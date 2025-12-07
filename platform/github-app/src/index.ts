import { Probot, Context } from "probot";

// Configuration
const TEMPLATE_REPO = "azure-project-template";
const VALID_ORGS = ["nl", "pvc", "tws", "mys"];
const VALID_ENVS = ["dev", "staging", "prod"];
const VALID_STACKS = [
  "fastapi",
  "fastapi-hexagonal",
  "nodejs",
  "go",
  "dotnet",
  "flutter",
  "reactnative",
];
const VALID_REGIONS = ["euw", "eus", "wus", "san", "saf"];

interface InitConfig {
  org: string;
  env: string;
  project: string;
  techstack: string;
  region: string;
}

/**
 * Parse /init command from comment
 * Format: /init org=nl env=dev project=myapp stack=fastapi region=euw
 */
function parseInitCommand(comment: string): InitConfig | null {
  if (!comment.trim().startsWith("/init")) {
    return null;
  }

  const config: Partial<InitConfig> = {};

  // Extract key=value pairs
  const matches = comment.matchAll(/(\w+)=(\w+)/g);
  for (const match of matches) {
    const [, key, value] = match;
    switch (key) {
      case "org":
        config.org = value;
        break;
      case "env":
        config.env = value;
        break;
      case "project":
        config.project = value;
        break;
      case "stack":
      case "techstack":
        config.techstack = value;
        break;
      case "region":
        config.region = value;
        break;
    }
  }

  // Validate required fields
  if (!config.org || !config.env || !config.project || !config.techstack) {
    return null;
  }

  // Set defaults
  config.region = config.region || "euw";

  return config as InitConfig;
}

/**
 * Validate configuration values
 */
function validateConfig(config: InitConfig): string[] {
  const errors: string[] = [];

  if (!VALID_ORGS.includes(config.org)) {
    errors.push(`Invalid org "${config.org}". Valid: ${VALID_ORGS.join(", ")}`);
  }

  if (!VALID_ENVS.includes(config.env)) {
    errors.push(`Invalid env "${config.env}". Valid: ${VALID_ENVS.join(", ")}`);
  }

  if (!VALID_STACKS.includes(config.techstack)) {
    errors.push(
      `Invalid stack "${config.techstack}". Valid: ${VALID_STACKS.join(", ")}`
    );
  }

  if (!VALID_REGIONS.includes(config.region)) {
    errors.push(
      `Invalid region "${config.region}". Valid: ${VALID_REGIONS.join(", ")}`
    );
  }

  if (!/^[a-z0-9]{2,20}$/.test(config.project)) {
    errors.push(
      `Invalid project name "${config.project}". Must be 2-20 lowercase alphanumeric characters.`
    );
  }

  return errors;
}

export default (app: Probot) => {
  app.log.info("Phoenix Project Initializer started!");

  // ==========================================================================
  // Handle new repository creation
  // ==========================================================================
  app.on("repository.created", async (context) => {
    const { repository, sender } = context.payload;

    app.log.info(`New repository created: ${repository.full_name}`);

    // Check if created from our template
    const isFromTemplate =
      (repository as any).template_repository?.name === TEMPLATE_REPO;

    if (!isFromTemplate) {
      app.log.info("Not created from template, ignoring");
      return;
    }

    app.log.info(
      `Repository ${repository.name} created from ${TEMPLATE_REPO} by ${sender.login}`
    );

    // Try to parse repo name for auto-configuration
    const parts = repository.name.split("-");
    let shouldAutoInit = false;
    let config: InitConfig | null = null;

    if (parts.length >= 4) {
      config = {
        org: parts[0],
        env: parts[1],
        project: parts[2],
        techstack: parts.slice(3).join("-"), // Handle stacks like "fastapi-hexagonal"
        region: "euw",
      };

      const errors = validateConfig(config);
      if (errors.length === 0) {
        shouldAutoInit = true;
      }
    }

    if (shouldAutoInit && config) {
      // Trigger the initialization workflow
      app.log.info(`Auto-initializing with config: ${JSON.stringify(config)}`);

      try {
        await context.octokit.actions.createWorkflowDispatch({
          owner: repository.owner.login,
          repo: repository.name,
          workflow_id: "template-setup.yml",
          ref: repository.default_branch || "main",
          inputs: {
            org: config.org,
            env: config.env,
            project: config.project,
            techstack: config.techstack,
            region: config.region,
          },
        });

        app.log.info("Workflow dispatch triggered successfully");
      } catch (error) {
        app.log.error(`Failed to trigger workflow: ${error}`);
      }
    } else {
      // Create a welcome issue with setup instructions
      app.log.info("Creating setup instructions issue");

      try {
        await context.octokit.issues.create({
          owner: repository.owner.login,
          repo: repository.name,
          title: "🚀 Initialize Your Project",
          labels: ["setup"],
          body: `## Welcome to your new project, @${sender.login}! 👋

Your repository was created from the **azure-project-template**. Let's get it configured!

### Option 1: Use the Visual Form (Recommended)

1. Go to the **[Actions tab](/${repository.full_name}/actions)**
2. Click on **"🚀 Initialize Project"** workflow
3. Click **"Run workflow"** button
4. Fill in the form and submit

### Option 2: Use a Slash Command

Reply to this issue with:

\`\`\`
/init org=<org> env=<env> project=<name> stack=<stack>
\`\`\`

**Example:**
\`\`\`
/init org=nl env=dev project=myapi stack=fastapi
\`\`\`

### Available Options

| Option | Values |
|--------|--------|
| **org** | \`nl\`, \`pvc\`, \`tws\`, \`mys\` |
| **env** | \`dev\`, \`staging\`, \`prod\` |
| **stack** | \`fastapi\`, \`fastapi-hexagonal\`, \`nodejs\`, \`go\`, \`dotnet\`, \`flutter\`, \`reactnative\` |
| **region** | \`euw\` (default), \`eus\`, \`wus\`, \`san\`, \`saf\` |

---
*This issue was created automatically by the Phoenix Project Initializer.*`,
        });

        app.log.info("Setup issue created successfully");
      } catch (error) {
        app.log.error(`Failed to create issue: ${error}`);
      }
    }
  });

  // ==========================================================================
  // Handle /init command in issue comments
  // ==========================================================================
  app.on("issue_comment.created", async (context) => {
    const { comment, issue, repository } = context.payload;

    // Only process comments on issues with 'setup' label
    const hasSetupLabel = issue.labels?.some(
      (label: { name: string }) => label.name === "setup"
    );

    if (!hasSetupLabel) {
      return;
    }

    const config = parseInitCommand(comment.body);

    if (!config) {
      // Not an /init command, ignore
      return;
    }

    app.log.info(`Received /init command: ${JSON.stringify(config)}`);

    // Validate configuration
    const errors = validateConfig(config);

    if (errors.length > 0) {
      // Reply with validation errors
      await context.octokit.issues.createComment({
        owner: repository.owner.login,
        repo: repository.name,
        issue_number: issue.number,
        body: `## ❌ Invalid Configuration

${errors.map((e) => `- ${e}`).join("\n")}

Please fix the errors and try again.

**Example:**
\`\`\`
/init org=nl env=dev project=myapi stack=fastapi
\`\`\``,
      });
      return;
    }

    // Add reaction to show we're processing
    await context.octokit.reactions.createForIssueComment({
      owner: repository.owner.login,
      repo: repository.name,
      comment_id: comment.id,
      content: "rocket",
    });

    // Trigger the initialization workflow
    try {
      await context.octokit.actions.createWorkflowDispatch({
        owner: repository.owner.login,
        repo: repository.name,
        workflow_id: "template-setup.yml",
        ref: repository.default_branch || "main",
        inputs: {
          org: config.org,
          env: config.env,
          project: config.project,
          techstack: config.techstack,
          region: config.region,
        },
      });

      await context.octokit.issues.createComment({
        owner: repository.owner.login,
        repo: repository.name,
        issue_number: issue.number,
        body: `## 🚀 Initialization Started!

**Configuration:**
| Setting | Value |
|---------|-------|
| Organization | \`${config.org}\` |
| Environment | \`${config.env}\` |
| Project | \`${config.project}\` |
| Tech Stack | \`${config.techstack}\` |
| Region | \`${config.region}\` |

The setup workflow has been triggered. This issue will be automatically closed when initialization completes.

[View workflow progress](/${repository.full_name}/actions)`,
      });
    } catch (error) {
      app.log.error(`Failed to trigger workflow: ${error}`);

      await context.octokit.issues.createComment({
        owner: repository.owner.login,
        repo: repository.name,
        issue_number: issue.number,
        body: `## ❌ Failed to Start Initialization

An error occurred while triggering the setup workflow. Please try using the [Actions tab](/${repository.full_name}/actions) directly.

Error: ${error}`,
      });
    }
  });

  // ==========================================================================
  // Handle workflow completion
  // ==========================================================================
  app.on("workflow_run.completed", async (context) => {
    const { workflow_run, repository } = context.payload;

    // Only handle our setup workflow
    if (workflow_run.name !== "🚀 Initialize Project") {
      return;
    }

    app.log.info(
      `Workflow ${workflow_run.name} completed with status: ${workflow_run.conclusion}`
    );

    // Find and close setup issues if successful
    if (workflow_run.conclusion === "success") {
      try {
        const issues = await context.octokit.issues.listForRepo({
          owner: repository.owner.login,
          repo: repository.name,
          labels: "setup",
          state: "open",
        });

        for (const issue of issues.data) {
          await context.octokit.issues.update({
            owner: repository.owner.login,
            repo: repository.name,
            issue_number: issue.number,
            state: "closed",
          });

          await context.octokit.issues.createComment({
            owner: repository.owner.login,
            repo: repository.name,
            issue_number: issue.number,
            body: `## ✅ Project Initialized Successfully!

Your project is ready to use. Get started:

\`\`\`bash
git clone ${repository.clone_url}
cd ${repository.name}
make install
make dev
\`\`\`

Happy coding! 🎉`,
          });
        }
      } catch (error) {
        app.log.error(`Failed to close setup issues: ${error}`);
      }
    }
  });
};
