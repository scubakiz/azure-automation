using MathTrickCore.Interfaces;
using MathTrickCore.Models;
using MathTrickCore.Providers;
using MathTrickCore.Extensions;
using MT3Gateway_Step3.Services;
using Microsoft.Extensions.Options;
using Microsoft.ApplicationInsights.Extensibility;
using MT3Gateway_Step3;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHttpClient();
builder.Services.AddSwaggerGen();
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameInitializer>();
builder.Services.AddSingleton<ICalculationService, CalculationService>();
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


app.MapPost("/Calculations", async (HttpContext context, ICalculationService calculationService) =>
{
    try
    {
        if (context.Request.HasJsonContentType())
        {
            CurrentCalculation? currentCalculation = await context.Request.ReadFromJsonAsync<CurrentCalculation>();
            if (currentCalculation == null)
            {
                return Results.BadRequest("Invalid JSON content.");
            }
            return Results.Ok(calculationService.CalculateStep(currentCalculation));
        }
        else
        {
            return Results.BadRequest("Invalid content type.");
        }
    }
    catch (Exception ex)
    {
        var steps = new CalculationStepModel
        {
            CalcStep = "3",
            CalcPerformed = "MT3Gateway-Step3",
            CalcResult = $"Exception: {ex.Message}"
        };
        return Results.Ok(steps);
    }
})
.WithOpenApi();

app.Run();
