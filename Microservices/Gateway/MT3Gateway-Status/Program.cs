using MathTrickCore.Interfaces;
using MathTrickCore.Extensions;
using Microsoft.ApplicationInsights.Extensibility;
using MT3Gateway_Status;

using MathTrickCore.Models;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json.Serialization;
using Dapr;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHttpClient();
builder.Services.AddSwaggerGen();
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameInitializer>();
// Registrer event bus provider based on external configuration values
builder.Services.RegisterEventBusProvider(builder.Configuration);
var app = builder.Build();


// Dapr configurations
app.UseCloudEvents();
app.MapSubscribeHandler();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Register Dapr pub/sub subscriptions
//app.MapGet("/dapr/subscribe", () =>
//{
//    var sub = new DaprSubscription(PubsubName: "gatewaypubsub", Topic: "status_queue", Route: "/status");
//    Console.WriteLine("Dapr pub/sub is subscribed to: " + sub);
//    return Results.Json(new DaprSubscription[] { sub });
//});

app.MapPost("/status", [Topic("gatewaypubsub", "status_queue")] (ILogger<Program> logger, StatusMessageModel statusMessage) =>
{
    logger.LogInformation($"MT3Gateway-Status: Source: {statusMessage.MessageSource} - Status: {statusMessage.CurrentStatus}");
    return Results.Ok(statusMessage);
})
.WithOpenApi();

//app.MapPost("/status", (ILogger<Program> logger, StatusMessageModel statusMessage) => {
//    logger.LogInformation($"MT3Gateway-Status: Source: {statusMessage.MessageSource} - Status: {statusMessage.CurrentStatus}");
//    return Results.Ok(statusMessage);
//})
//.WithOpenApi();

await app.RunAsync();

//public record DaprData<T>([property: JsonPropertyName("data")] T Data);
//public record DaprSubscription(
//  [property: JsonPropertyName("pubsubname")] string PubsubName,
//  [property: JsonPropertyName("topic")] string Topic,
//  [property: JsonPropertyName("route")] string Route);
