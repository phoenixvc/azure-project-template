using Microsoft.AspNetCore.Builder;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => new { message = "{{PROJECT}}", org = "{{ORG}}", env = "{{ENV}}" });
app.MapGet("/health", () => new { status = "healthy" });

app.Run();
