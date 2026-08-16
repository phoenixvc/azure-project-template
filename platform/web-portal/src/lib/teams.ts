export interface TeamsNotification {
  projectName: string;
  org: string;
  env: string;
  techstack: string;
  region: string;
  repoUrl: string;
}

export async function sendTeamsNotification(data: TeamsNotification): Promise<void> {
  const webhookUrl = process.env.TEAMS_WEBHOOK_URL;

  if (!webhookUrl) {
    console.warn('TEAMS_WEBHOOK_URL not configured — skipping Teams notification');
    return;
  }

  const card = {
    type: 'message',
    attachments: [
      {
        contentType: 'application/vnd.microsoft.card.adaptive',
        content: {
          type: 'AdaptiveCard',
          version: '1.4',
          body: [
            {
              type: 'TextBlock',
              text: '🚀 New Project Created',
              weight: 'Bolder',
              size: 'Large',
            },
            {
              type: 'FactSet',
              facts: [
                { title: 'Project', value: data.projectName },
                { title: 'Organization', value: data.org },
                { title: 'Environment', value: data.env },
                { title: 'Tech Stack', value: data.techstack },
                { title: 'Region', value: data.region },
                { title: 'Resource Group', value: `${data.org}-${data.env}-${data.projectName}-rg-${data.region}` },
              ],
            },
          ],
          actions: [
            {
              type: 'Action.OpenUrl',
              title: 'View Repository',
              url: data.repoUrl,
            },
          ],
        },
      },
    ],
  };

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(card),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Teams webhook failed (${response.status}): ${text}`);
  }
}
