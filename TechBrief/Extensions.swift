import SwiftUI

// MARK: - Accent color shorthand

extension Color {
    static let accent = Color(red: 0.145, green: 0.388, blue: 0.918)
}

// MARK: - Preview data

extension Brief {
    static let preview = Brief(
        topic: "Docker",
        tagline: "Run anything, anywhere — without the 'works on my machine' headache.",
        whatIsIt: "Docker is an open-source platform that packages your application and all its dependencies into a lightweight, portable unit called a container. Containers run identically on any machine that has Docker installed.",
        whyItMatters: "Before Docker, deploying software was painful. Code that worked perfectly on a developer's machine often crashed in production due to different OS versions or missing libraries. Docker eliminates this by bundling everything your app needs into one portable box.",
        concepts: [
            Concept(term: "Image", definition: "A read-only blueprint for a container — like a snapshot of your app + its environment."),
            Concept(term: "Container", definition: "A running instance of an image. Isolated, lightweight, and disposable."),
            Concept(term: "Dockerfile", definition: "A plain-text script of instructions Docker uses to build an image."),
            Concept(term: "Docker Hub", definition: "A public registry where you pull pre-built images (e.g. nginx, postgres, node)."),
            Concept(term: "Volume", definition: "Persistent storage that survives container restarts — for databases, uploads, etc."),
            Concept(term: "Docker Compose", definition: "A YAML file that defines and runs multi-container apps."),
        ],
        useWhen: ["Consistent dev/prod environments", "Deploying microservices", "Onboarding new devs fast", "Multiple app versions side-by-side"],
        avoidWhen: ["Direct GPU or kernel access needed", "Tiny scripts with no dependencies", "Strong VM isolation required", "No DevOps knowledge on the team"],
        codeComment: "A minimal Dockerfile for a Node.js app",
        codeLines: [
            "# Start from an official Node image",
            "FROM node:20-alpine",
            "",
            "WORKDIR /app",
            "COPY package*.json ./",
            "RUN npm install",
            "COPY . .",
            "EXPOSE 3000",
            "CMD [\"node\", \"index.js\"]",
        ],
        youtubeLinks: [
            YouTubeLink(title: "Docker in 100 Seconds", channel: "Fireship", duration: "2 min", url: "youtube.com/watch?v=Gjnup-PuquQ"),
            YouTubeLink(title: "Docker Tutorial for Beginners", channel: "TechWorld with Nana", duration: "13 min", url: "youtube.com/watch?v=3c-iBn73dDE"),
            YouTubeLink(title: "Docker Compose in 12 Minutes", channel: "Jake Wright", duration: "12 min", url: "youtube.com/watch?v=Qw9zlE3t8Ko"),
        ],
        learnNext: [
            NextTopic(topic: "Kubernetes", description: "Once you have multiple containers, Kubernetes orchestrates them at scale."),
            NextTopic(topic: "Docker Compose", description: "Go deeper with multi-service apps, env files, and health checks."),
            NextTopic(topic: "CI/CD Pipelines", description: "Automate Docker builds into GitHub Actions so every merge ships a fresh container."),
        ]
    )
}
