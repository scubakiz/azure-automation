using MathTrickCore.Interfaces;
using MathTrickCore.Models;
using MathTrickCore.Providers;
using MathTrickCore.Extensions;
using MT3Gateway_Gateway.Services;
using Microsoft.ApplicationInsights.Extensibility;
using MT3Gateway_Gateway;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHttpClient();
builder.Services.AddSwaggerGen();
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameInitializer>();
builder.Services.AddSingleton<ICalculateAllService, CalculateAllService>();
// Registrer the communications provider and event bus provider based on external configuration values
builder.Services.RegisterComminicationsProvider(builder.Configuration);
builder.Services.RegisterEventBusProvider(builder.Configuration);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
             
app.MapGet("/Calculations/{pickedNumber}", (
        ICalculateAllService calculateAllService,
        ICommunicationsProvider commHelper,
        int pickedNumber) =>
{
    try
    {
        return Results.Ok(calculateAllService.CallCalculateSteps(pickedNumber));
    }
    catch (Exception ex)
    {
        var steps = new List<CalculationStepModel>
        {
            new()
            {
                CalcStep = "0",
                CalcPerformed = "MT3Gateway-Gateway",
                CalcResult = $"Exception: {ex.Message}"
            }
        };
        return Results.Ok(steps);
    }
})
.WithOpenApi();

app.Run();
