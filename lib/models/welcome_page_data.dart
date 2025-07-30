class WelcomePageData {
  final String title;
  final String description;
  final String mainImage;
  final bool isLastPage;

  const WelcomePageData({
    required this.title,
    required this.description,
    required this.mainImage,
    this.isLastPage = false,
  });

  static List<WelcomePageData> get welcomePages => [
    const WelcomePageData(
      title: "Your AI-Powered\nCareer Assistant",
      description:
          "Get ready to craft smarter resumes, master interviews, and unlock career opportunities.",
      mainImage: "assets/icons/welcome1.png",
    ),
    const WelcomePageData(
      title: "Your AI-Powered\nStudy Assistant",
      description:
          "Get ready to rely on your own assistant to help you take lecture and meeting notes, create custom quiz questions for advanced studying sessions to help you ace your tests!",
      mainImage: "assets/icons/welcome2.png",
    ),
    const WelcomePageData(
      title: "Generate Tailored,\nResumes In Seconds",
      description:
          "Create AI-smart resumes that will help you land an interview. Just input what job you want and the company you're applying to - we will Scout the internet to make your resume the most appealing!",
      mainImage: "assets/icons/welcome3.png",
    ),
    const WelcomePageData(
      title: "Our AI-Powered\nInterview Assistant",
      description:
          "Practice, improve, gain feedback and conduct LIVE interviews with the help of your AI assistant who is ready to give you all of the answers to the interviewers questions so you can out fox the interview!",
      mainImage: "assets/icons/welcome4.png",
    ),
    const WelcomePageData(
      title: "Track Your Career\nJourney",
      description:
          "Manage resumes, track their success rates, review interview sessions, get pro, post and live interview assistance to help you land your dream job.",
      mainImage: "assets/icons/welcome5.png",
      isLastPage: true,
    ),
  ];
}
