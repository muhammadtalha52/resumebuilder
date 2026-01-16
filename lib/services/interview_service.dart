import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../main.dart';
import '../models/interview_session_models.dart';
import '../models/meeting_history_response.dart';
import '../utils/endpoint_headers.dart';
import 'hmac_auth_service.dart';

class InterviewService {
  late final Dio _dioForInterview;

  InterviewService() {
    _dioForInterview = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.interviewModuleBaseUrl,
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5), // Fast send timeout
      ),
    );

    // Configure SSL/TLS for development server
    (_dioForInterview.httpClientAdapter as IOHttpClientAdapter)
        .createHttpClient = () {
      final client = HttpClient();
      // For development server - bypass certificate verification
      client.badCertificateCallback = (cert, host, port) {
        // Only bypass for our specific development server
        return host.contains('ia-dev.skillresy.com') ||
            host.contains('skillresy.com');
      };
      return client;
    };

    // Add HMAC authentication interceptor
    _dioForInterview.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add HMAC auth headers to every request
          final authHeaders = HmacAuthService.buildAuthHeaders();
          options.headers.addAll(authHeaders);
          return handler.next(options);
        },
      ),
    );

    // Note: Removed LogInterceptor to reduce console spam during streaming
  }

  /// Start a new interview session
  ///
  /// [request] - SessionStartRequest containing session parameters
  ///
  /// Returns a SessionStartResponse with status and session_id
  Future<SessionStartResponse> startSession(SessionStartRequest request) async {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = <String, dynamic>{
        'session_type': request.sessionType,
        'role': request.role,
        'company_name': request.companyName,
        'job_description': request.jobDescription,
        'agenda': request.agenda,
        'language': request.language,
        'resume_text': request.resumeText,
      };

      // Debug log for resume_text
      final resumeLength = (request.resumeText?.length ?? 0);
      print(
        '[API] Sending session start request with resume_text: ${resumeLength > 0 ? '$resumeLength chars' : 'empty'}',
      );

      // Make API call with form data
      final response = await _dioForInterview.post(
        ApiEndpoints.sessionStart,
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return SessionStartResponse.fromJson(response.data);
        } else {
          return SessionStartResponse.failure('Empty response from server');
        }
      } else {
        return SessionStartResponse.failure(
          'Failed to start session: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return SessionStartResponse.failure(
          'Request timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        return SessionStartResponse.failure(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 400) {
        return SessionStartResponse.failure(
          'Invalid session parameters. Please check your inputs and try again.',
        );
      } else if (e.response?.statusCode == 401) {
        return SessionStartResponse.failure(
          'Authentication required. Please log in and try again.',
        );
      } else if (e.response?.statusCode == 422) {
        return SessionStartResponse.failure(
          'Unable to process your request. Please verify your data and try again.',
        );
      } else if (e.response?.statusCode == 500) {
        return SessionStartResponse.failure(
          'Server error occurred while starting session. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage =
            'An error occurred while starting session. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        return SessionStartResponse.failure(errorMessage);
      }
    } catch (e) {
      return SessionStartResponse.failure(
        'Unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get streaming help during interview session
  ///
  /// [request] - SessionHelpRequest containing session_id and transcript
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive
  Stream<String> getHelpStreaming(SessionHelpRequest request) async* {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make streaming API call
      final response = await _dioForInterview.post(
        'interview/help',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
      );

      print('InterviewService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final streamController = StreamController<String>();

        // Process the stream data
        String buffer = '';

        stream.stream.listen(
          (List<int> data) {
            // Convert bytes to string
            final chunk = utf8.decode(data, allowMalformed: true);
            buffer += chunk;

            // Split by newlines and process complete lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast(); // Keep incomplete line in buffer

            for (final line in lines) {
              // Parse Server-Sent Events format: "data: content"
              if (line.startsWith('data: ')) {
                final content = line.substring(6); // Remove "data: " prefix
                streamController.add(content);
              }
            }
          },
          onError: (error) {
            print('InterviewService: Stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              print('InterviewService: Final content: "$content"');
              streamController.add(content);
            }
            print('InterviewService: Stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'interview/help'),
          response: response,
          message: 'Failed to get streaming help: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('InterviewService: DioException: ${e.message}');

      // Handle specific error cases
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Error: Request timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Error: Unable to connect to server. Please check your internet connection.';
      } else if (e.response?.statusCode == 400) {
        yield 'Error: Invalid request. Please check your session or transcript.';
      } else if (e.response?.statusCode == 401) {
        yield 'Error: Session not found or expired. Please start a new session.';
      } else if (e.response?.statusCode == 422) {
        yield 'Error: Unable to process your request. Please try again.';
      } else if (e.response?.statusCode == 500) {
        yield 'Error: Server error occurred while getting help. Please try again later.';
      } else {
        yield 'Error: An error occurred while getting help. Please try again.';
      }
    } catch (e) {
      print('InterviewService: General exception: $e');
      yield 'Error: Unexpected error occurred: ${e.toString()}';
    }
  }

  /// Get next meeting assistance during meeting session
  ///
  /// [request] - SessionHelpRequest containing session_id and transcript
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive for meeting assistance
  Stream<String> getNextMeetingHelp(SessionHelpRequest request) async* {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make streaming API call to /next endpoint
      final response = await _dioForInterview.post(
        'meeting/next',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
      );

      print('InterviewService: Next response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final streamController = StreamController<String>();

        // Process the stream data
        String buffer = '';

        stream.stream.listen(
          (List<int> data) {
            // Convert bytes to string
            final chunk = utf8.decode(data, allowMalformed: true);
            buffer += chunk;

            // Split by newlines and process complete lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast(); // Keep incomplete line in buffer

            for (final line in lines) {
              // Parse Server-Sent Events format: "data: content"
              if (line.startsWith('data: ')) {
                final content = line.substring(6); // Remove "data: " prefix
                streamController.add(content);
              }
            }
          },
          onError: (error) {
            print('InterviewService: Next stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              print('InterviewService: Final next content: "$content"');
              streamController.add(content);
            }
            print('InterviewService: Next stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'interview/next'),
          response: response,
          message: 'Failed to get next meeting help: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('InterviewService: Next DioException: ${e.message}');

      // Handle specific error cases
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Error: Request timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Error: Unable to connect to server. Please check your internet connection.';
      } else if (e.response?.statusCode == 400) {
        yield 'Error: Invalid request. Please check your session or transcript.';
      } else if (e.response?.statusCode == 401) {
        yield 'Error: Session not found or expired. Please start a new session.';
      } else if (e.response?.statusCode == 422) {
        yield 'Error: Unable to process your request. Please try again.';
      } else if (e.response?.statusCode == 500) {
        yield 'Error: Server error occurred while getting meeting help. Please try again later.';
      } else {
        yield 'Error: An error occurred while getting meeting help. Please try again.';
      }
    } catch (e) {
      print('InterviewService: Next general exception: $e');
      yield 'Error: Unexpected error occurred: ${e.toString()}';
    }
  }

  /// Get streaming follow-up questions during interview session
  ///
  /// [request] - SessionFollowUpRequest containing session_id and transcript
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive
  Stream<String> getFollowUpQuestionsStreaming(
    SessionFollowUpRequest request,
  ) async* {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make streaming API call
      final response = await _dioForInterview.post(
        'interview/follow-up',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
      );

      print(
        'InterviewService: Follow-up response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final streamController = StreamController<String>();

        // Process the stream data
        String buffer = '';

        stream.stream.listen(
          (List<int> data) {
            // Convert bytes to string
            final chunk = utf8.decode(data, allowMalformed: true);
            buffer += chunk;

            // Split by newlines and process complete lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast(); // Keep incomplete line in buffer

            for (final line in lines) {
              // Parse Server-Sent Events format: "data: content"
              if (line.startsWith('data: ')) {
                final content = line.substring(6); // Remove "data: " prefix
                streamController.add(content);
              }
            }
          },
          onError: (error) {
            print('InterviewService: Follow-up stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              print('InterviewService: Final follow-up content: "$content"');
              streamController.add(content);
            }
            print('InterviewService: Follow-up stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'interview/follow-up'),
          response: response,
          message:
              'Failed to get streaming follow-up: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('InterviewService: Follow-up DioException: ${e.message}');

      // Handle specific error cases
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Error: Request timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Error: Unable to connect to server. Please check your internet connection.';
      } else if (e.response?.statusCode == 400) {
        yield 'Error: Invalid request. Please check your session or transcript.';
      } else if (e.response?.statusCode == 401) {
        yield 'Error: Session not found or expired. Please start a new session.';
      } else if (e.response?.statusCode == 422) {
        yield 'Error: Unable to process your request. Please try again.';
      } else if (e.response?.statusCode == 500) {
        yield 'Error: Server error occurred while getting follow-up questions. Please try again later.';
      } else {
        yield 'Error: An error occurred while getting follow-up questions. Please try again.';
      }
    } catch (e) {
      print('InterviewService: Follow-up general exception: $e');
      yield 'Error: Unexpected error occurred: ${e.toString()}';
    }
  }

  /// End an interview session and get summary
  ///
  /// [sessionId] - The session ID to end
  /// [transcription] - The full transcription from the session
  ///
  /// Returns a Map containing status and summary
  Future<Map<String, dynamic>> endSession(
    String sessionId, {
    String? transcription,
  }) async {
    ///TODO for testing with crystal
    // transcription = '''So what what we've created here has been and, you know, there's nothing's perfect. But the resume process and you started with that has, has has evolved. And, obviously, artificial intelligence is a we know we're offering master's degree program now in AI. In the Seidenberg School of Technology beginning next year. Beginning of the fall rather. Wonderful. So AI is a double edged sword. I I know, it's a necessary tool for people to master, and I tell students, you know, AI is not gonna replace your job or your career, but those who know how to master it are. That said, we're not encouraging students to have AI right there resumes or their cover letters. So there's this final line of where does AI work as a tool, and where does it diminish critical thinking creativity, you know, like a calculator, It's you know, well, math skills have have dissolved in a lot of places. You know? Math. So well, are are we too dependent upon machines to do our adding for us or Right. Calculations. But math still needs to be understood. Right. I don't wanna go down that path, but so we we have a very robust know, it's workshops. It's career fairs. It's Mhmm. There are several of our schools here. We have mandatory you need to go to x number of workshops, the career fair. You need to have your resume done. Mhmm. It needs to be a an ATS compliant resume. Right. It needs to pass muster with us. I've seen thousands of resumes, you know, in my previous life, you know, hiring and actually look looking for a job later in my career, it it was imperative that resumes were were air But resin I hear you about resumes need to be different in resume. But the the what we're trying to reinforce here not just your resume. LinkedIn is a huge component of what we foster here in terms of how to make connections, establish an online brand presence, and so forth. Cover letters, we reinforce that the value of cover letters are very important. Mhmm. We do interviewing skills and role mock mock up roles, role model playing, salary negotiation, which have alumni who come back. So we have a lot of bandwidth here in what we're doing with this. Great. My question is this, is that, you know, the resume is great. We know the resume is the first probably the first document. Maybe LinkedIn is even more critical these days I see. That hiring managers and talent acquisition and HR managers are gonna look at. Yeah. And they took some average of eight seconds to view those view those resumes. Yeah. We are trying to reinforce that it's search applied network. You need to net you need to build a network. Your resume applying the the reason why a thousand people are just applying and getting no response is they're not network They're not networking, and they're not following up. Mhmm. I'm gonna just cut right to the chase. Yeah. They're not they're not drilling deep into organizations. They're writing cookie cutter cover letters and just swapping out names and saying what they do. And they're not you know, the resumes for student there's not too many places you can customize your resume. You've got a couple of internships. You've got on campus leadership. Mhmm. You've got school coursework. You've got a GPA. You've got a much of other things. So it's not like you're gonna really, you know, change this around to fit other types of jobs. You have the sort words that are important. The job description. Many students don't even read job descriptions. They just, oh, I see a job for, you know, marketing coordinator. I'm gonna apply. And they Right. Don't see that the job is requiring you know, Python and data analytics in addition to marketing. Capabilities. So it's really preparation. So I'm just saying here's what I'm saying. I I I I think that I appreciate you reaching out, but I don't know. I mean, we've got so many of these different software platforms that we use. We've used Resume Worded. We have Copilot, which we use to kinda, like, examine resumes sometimes. Mhmm. Jatchi PPT. We used some other resume sources, source work. My opinion, the best resume viewer is human beings. To find out exactly what this student does what their skills are. Agree with you more. So sorry to interrupt you. But that's the reason why I'm doing this. It's not like putting it through some machine to pump up their resume and make things look better than what they are. Right. And I'm saying I'm not saying that I'm just saying that we're not trying to encourage students to I mean, I get a lot of I I have a lot of employers who send back don't have students send us AI AI driven cover letters because we'll throw them out. Well They wanna see how they effectively communicate. So how you gonna determine who communicates I understand. Yes. And if you're using ChatGPT for resume review, I could say this. ChatGPT is not going to do that. It can't No. It's got its it's got its fault. It doesn't It can't learn you. Like you said, it can't learn you. It doesn't know all of your skills, and it can't do what mine does. Mine will cross reference you, and it won't lie. ChatGPT doesn't know to not lie. It will lie. Are working with other schools right now too? Colleges? So to be honest with you, this is new. I just launched it, and I'm reaching out to schools to try and adopt it. So I haven't gotten I'm I'm starting my traction. It's you know, the the holiday season is a tough time to start to try and gain relationships because nobody's there. So so I'm I'm this is, you know, January is my start. This is yeah. So you know, I I mean, I just like to, you know, keep in touch. I don't wanna send students your way and say, here's this magic formula. You know? I just I you know, maybe you can show me some test success examples or things that Sure. I can send you a link to yeah. Share with you where you're working with and what kind of students you've been doing this with. I mean, that's always a good you know, I I I I commend you, and I I I understand you. You're in a stored up environment. You're storing up your own Yeah. Business. I think that's fantastic. I think I think yeah. The other thing that you know, yes, there's the resume component to it, but there's a whole separate other plat not platform, but sign up screen. So there's a sign up screen for students, and there's a sign up screen for career. So the student portion just is for studying. I don't have any of the resume stuff on there. All it is is to they can upload their documents from their courses. They can customize the study path. And if they you know, say their professor says, you have a test this Friday on these chapters. Well, then they can specifically select the chapters it will generate quiz questions for them. Based on those study materials so that they can study better. Because I do think that it's something that you know, a lot of kids are on their phone. They like being on their phone. So I created something where they can study on their phone using the course material. It's not gonna bring up know, if you if you ask ChatGPT, create materials on you know, social studies one zero one or whatever whatever it is. It's gonna bring up stuff that's not having to do with anything from your class. But if you're uploading your materials and you're able to give multiple downloads of materials, to then create customized quizzes. It creates 20 to 30 question quizzes for you. It's easy. It's digestible. It's not horrible for the student. And it just gives them a a chance to find a new way to study. So there's that portion. And then to your point, I understand that you don't want the students to not prepare. So part of my platform on the career side for the interview assisting I have practice interview sessions that they can use where it will ask them questions they have to answer, and then it's kind of analyzed after the fact. It also gives them follow-up tips. Right. You know, students don't know. They have to email the interviewer at thank you email. Thank you for your time. I'm super interested This is why I feel like we're aligned now. I can give them an example of what a thank you letter looks like. Just giving them those tips to follow-up Learn who the interviewer is. Research the company yourself. Add the the company motto, the company's you know, vision plans. You know, figure those things out and sneak them into your follow-up calls, follow-up emails, follow-up interviews. As a career recruiter, I've seen that that's where people go wrong, and I believe that a that that one, AI is ruining that human connection that really needs to be involved when interviewing for a job. So I'm doing this to help people, but then also what I really my my biggest goal is to show companies that use using AI, it's going to become this is what the interview process is going to become. It's gonna become AI versus AI. The company is using AI to screen out. The the candidate is using AI to help get in, and it's gonna be a game. And it's happening right now. AI versus AI. Been happening for a while. I mean, you have bots cleaning out resumes. Exactly. You know, 2025% of resumes make it to the hiring manager. Exactly. So what to see their eyes because the bots screen them out because they don't have the effective it's not, you know, so, so I I would be just, like, interested in keeping in touch, and I I can ask around here if there would be any, but I just you know, right now, we are just, like, so like, inundated with lots of platforms and technologies that it just we don't wanna be here's another thing for a student to look at. Yep. Our objective here is really counseling human interaction and using the technology combined with lots of human development. So it's like we're not like you know, we're just sending them to a website to work to do. So it's like we got a lot of resources here. So just maybe just keep in touch with me. I this. Sure. Maybe you wanna send me a few examples something that you've done that's been successful. Yeah. And, you know, let's keep keep our you know, keep in touch. Right? Yeah. And I do think that know, building a resume from scratch, of course, is an important for them to learn. But the process of customizing for each job, that's such a it takes hours. It takes hours. And it's just not something that is it it it can't be efficiently done without cutting corners. And and and being efficient with your time to try and find a job. So I'm trying to solve a problem that will help people save time to customize their resumes of they already have one that's built a general one. Now let's make it better and get you that job interview. Have you, have you approached any of the like, other schools in, like, in Connecticut at all about this? Like UConn or, you know, some of the smaller universities? I am Are you starting smaller? Yeah. I am starting I am starting small, but the the problem with that is that the there slowly to slower to respond, I think. And that's okay. You know, it's the beginning of the year. I get it. A lot sooner than we do. You know, I I I actually counsel and coach students on the side and professionals too on career coaching. So I've done executive coaching. I've done but I have a few students who come from other schools like Quinnipiac, and I'm amazed that Quinnipiac's a great school. Yeah. My one of my my oldest daughter graduated from there, but he said their career services is is is missing. He said they really don't not it's, like, not they're not engaged. So I found that very highly interesting that a school like that, which is charging 67 65, 70,000 dollars a year. It's not cheap. Yeah. So you know, I I let's keep in touch. I can certainly know, if you wanna send me some in more information, I'd be happy to look at it. Sure. And let's just keep the keep the dialogue going. Alright? Sounds good. I appreciate you taking the time to listen and learn what what I have out there and I could certainly send you some links Sure. I'd love to see them. Can learn a little bit more and maybe maybe you'll become comfortable or maybe it's something that as your AI you know, portion starts starts developing more, maybe it'll be something that they are interested in. Great. I'll I'll think more about you know, where we're going in 2026, and we'll just keep in touch. Sounds good. Sounds good. Thank you for your time, Sal. You're welcome. The are the kids back yet? Oh, yeah. They are. That's what the dog was barking about. Well, enjoy. You take care. Thanks again. Appreciate meeting you. You too. Thanks so much. Bye now. Bye bye.''';
    try {
      final formData = <String, dynamic>{
        'session_id': sessionId,
        'transcription': transcription ?? '',
      };

      final response = await _dioForInterview.post(
        'session/end',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("InterviewService: End session response: ${response.data}");
        if (response.data != null) {
          return response.data as Map<String, dynamic>;
        } else {
          return {'status': 'error', 'summary': 'Empty response from server'};
        }
      } else {
        return {
          'status': 'error',
          'summary': 'Failed to end session: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'status': 'error',
          'summary': 'Request timeout. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'summary': 'Unable to connect to server.'};
      } else if (e.response?.statusCode == 400) {
        return {'status': 'error', 'summary': 'Invalid session ID.'};
      } else if (e.response?.statusCode == 401) {
        return {'status': 'error', 'summary': 'Session not found or expired.'};
      } else if (e.response?.statusCode == 500) {
        return {
          'status': 'error',
          'summary': 'Server error occurred while ending session.',
        };
      } else {
        String errorMessage = 'An error occurred while ending session.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        return {'status': 'error', 'summary': errorMessage};
      }
    } catch (e) {
      return {
        'status': 'error',
        'summary': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Save interview session to database using APIClient
  Future<Map<String, dynamic>> saveInterview(
    Map<String, dynamic> payloadData,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.saveInterviewData,
        data: payloadData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'data': response.data,
          'message': 'Meeting saved successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to save interview: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'status': 'error',
          'message': 'Request timeout. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'message': 'Unable to connect to server.'};
      } else if (e.response?.statusCode == 400) {
        return {'status': 'error', 'message': 'Invalid interview data.'};
      } else if (e.response?.statusCode == 401) {
        return {
          'status': 'error',
          'message': 'Authentication required. Please log in and try again.',
        };
      } else if (e.response?.statusCode == 403) {
        return {
          'status': 'error',
          'message': 'Permission denied. Unable to save interview.',
        };
      } else if (e.response?.statusCode == 500) {
        return {
          'status': 'error',
          'message': 'Server error occurred while saving interview.',
        };
      } else {
        String errorMessage = 'An error occurred while saving interview.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Setup Scout chat session for meeting history
  ///
  /// [sessionId] - The meeting session ID
  /// [meeting] - MeetingHistoryItem containing meeting data
  ///
  /// Returns a Map containing status and setup response
  Future<Map<String, dynamic>> setupScoutChatSession(
    int sessionId,
    MeetingHistoryItem meeting,
  ) async {
    try {
      // Prepare transcription from meeting data
      String transcription = _buildTranscriptionFromMeeting(meeting);

      print('Scout: Setting up chat session for meeting ID: $sessionId');
      print('Scout: Transcription length: ${transcription.length} chars');

      final formData = {
        'session_id': sessionId,
        'transcription': transcription,
      };

      final response = await _dioForInterview.post(
        'chat/start',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return {
            'status': 'success',
            'data': response.data,
            'message': 'Scout chat session setup successfully',
          };
        } else {
          return {
            'status': 'error',
            'message': 'Empty response from Scout chat setup',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to setup Scout chat: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'status': 'error',
          'message': 'Request timeout. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'status': 'error',
          'message': 'Unable to connect to Scout server.',
        };
      } else if (e.response?.statusCode == 400) {
        return {
          'status': 'error',
          'message': 'Invalid session data for Scout chat.',
        };
      } else if (e.response?.statusCode == 401) {
        return {
          'status': 'error',
          'message': 'Authentication required for Scout chat.',
        };
      } else if (e.response?.statusCode == 500) {
        return {
          'status': 'error',
          'message': 'Scout server error occurred. Please try again later.',
        };
      } else {
        String errorMessage = 'An error occurred while setting up Scout chat.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Unexpected Scout chat error: ${e.toString()}',
      };
    }
  }

  /// Send message to Scout chat with streaming response
  ///
  /// [sessionId] - The session ID for the chat
  /// [message] - User's message to Scout
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive
  Stream<String> sendScoutChatMessage(int sessionId, String message) async* {
    try {
      final formData = {
        'session_id': sessionId.toString(),
        'message': Uri.encodeComponent(message),
      };

      print('Scout: Sending message to session $sessionId');
      print('Scout: Message: $message');

      final response = await _dioForInterview.post(
        'chat/query',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final streamController = StreamController<String>();

        // Process the stream data
        String buffer = '';

        stream.stream.listen(
          (List<int> data) {
            // Convert bytes to string
            final chunk = utf8.decode(data, allowMalformed: true);
            buffer += chunk;

            // Split by newlines and process complete lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast(); // Keep incomplete line in buffer

            for (final line in lines) {
              // Parse Server-Sent Events format: "data: content"
              if (line.startsWith('data: ')) {
                final content = line.substring(6); // Remove "data: " prefix
                streamController.add(content);
              }
            }
          },
          onError: (error) {
            print('Scout: Stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              streamController.add(content);
            }
            print('Scout: Stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        yield 'Error: Failed to get response from Scout (${response.statusCode})';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Request timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Unable to connect to Scout server.';
      } else {
        String errorMessage = 'An error occurred while chatting with Scout.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        yield errorMessage;
      }
    } catch (e) {
      yield 'Unexpected error: ${e.toString()}';
    }
  }

  /// Build comprehensive transcription from meeting data
  String _buildTranscriptionFromMeeting(MeetingHistoryItem meeting) {
    List<String> transcriptionParts = [];

    // Add session type and basic info
    if (meeting.isInterview && meeting.companyName != null) {
      transcriptionParts.add(
        'This is an interview session for ${meeting.companyName}',
      );
      if (meeting.positionTitle != null) {
        transcriptionParts.add('for the position of ${meeting.positionTitle}');
      }
    } else if (meeting.isMeeting && meeting.roleIndustry != null) {
      transcriptionParts.add(
        'This is a meeting session in ${meeting.roleIndustry}',
      );
    }

    // Add actual transcript - this is the core conversation content
    if (meeting.transcript != null && meeting.transcript!.isNotEmpty) {
      transcriptionParts.add('Full transcript of the conversation:');
      transcriptionParts.add(meeting.transcript!);
    }

    // Add key topics discussed
    if (meeting.keyTopics != null && meeting.keyTopics!.isNotEmpty) {
      transcriptionParts.add('Key topics discussed included:');
      transcriptionParts.addAll(meeting.keyTopics!);
    }

    // Add top moments
    if (meeting.topMomentsInInterview != null &&
        meeting.topMomentsInInterview!.isNotEmpty) {
      transcriptionParts.add('Important moments in the session:');
      transcriptionParts.addAll(meeting.topMomentsInInterview!);
    }

    // Add decisions made
    if (meeting.decisionsMade != null && meeting.decisionsMade!.isNotEmpty) {
      transcriptionParts.add('Decisions made during the session:');
      transcriptionParts.addAll(meeting.decisionsMade!);
    }

    // Add strengths highlighted
    if (meeting.strengthHighlight != null &&
        meeting.strengthHighlight!.isNotEmpty) {
      transcriptionParts.add('Strengths highlighted:');
      transcriptionParts.addAll(meeting.strengthHighlight!);
    }

    // Add areas for improvement
    if (meeting.weaknessHighlight != null &&
        meeting.weaknessHighlight!.isNotEmpty) {
      transcriptionParts.add('Areas for improvement mentioned:');
      transcriptionParts.addAll(meeting.weaknessHighlight!);
    }

    // Add action items
    if (meeting.actionItems != null && meeting.actionItems!.isNotEmpty) {
      transcriptionParts.add('Action items identified:');
      transcriptionParts.addAll(meeting.actionItems!);
    }

    // Add AI analytics if available
    if (meeting.aiDrivenInterviewAnalytics != null &&
        meeting.aiDrivenInterviewAnalytics!.isNotEmpty) {
      transcriptionParts.add('AI-driven insights:');
      transcriptionParts.addAll(meeting.aiDrivenInterviewAnalytics!);
    }

    // Join all parts with proper spacing
    String result = transcriptionParts.join('. ');

    // If no content, provide basic info
    if (result.isEmpty) {
      result = meeting.isInterview
          ? 'This was an interview session'
          : 'This was a meeting session';
    }

    return result;
  }
}

// Custom exceptions for interview service
abstract class InterviewServiceException implements Exception {
  final String message;

  InterviewServiceException(this.message);

  @override
  String toString() => message;
}

class SessionStartException extends InterviewServiceException {
  SessionStartException(super.message);
}
