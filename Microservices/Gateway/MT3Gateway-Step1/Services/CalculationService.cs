using MathTrickCore.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;
using System.Text;
using MathTrickCore.Interfaces;

namespace MT3Gateway_Step1.Services
{
    public class CalculationService : ICalculationService
    {
        private readonly IConfiguration _configuration;
        private readonly IEventBusProvider _eventBusProvider;

        public CalculationService(IConfiguration configuration, IEventBusProvider eventBusProvider)
        {
            _configuration = configuration;
            _eventBusProvider = eventBusProvider;
        }

        public CalculationStepModel CalculateStep(CurrentCalculation currentCalculation)
        {
            var status = new StatusMessageModel()
            {
                MessageSource = "Step 1",
                CurrentStatus = $"Step 1 received {currentCalculation.PickedNumber} as the starting number."
            };
            _eventBusProvider.UpdateStatus(status);

            int failureRate = _configuration.GetValue<int>("FAILURE_RATE", 0);
            var rand = new Random();
            if (rand.NextDouble() < (failureRate / 100.0))
            {                
                status.CurrentStatus = $"Step 1 generated a random error for no good reason";
                _eventBusProvider.UpdateStatus(status);
                throw new Exception("Some random problem occurred.");
            }            

            // Perform current step
            // Step 1 - Double the number
            int multiplier = _configuration.GetValue<int>("CalcStepVariable", 2);
            currentCalculation.CurrentResult = currentCalculation.PickedNumber * multiplier;
            var resultCalculation = new CalculationStepModel()
            {
                CalcStep = "1",
                CalcPerformed = $"{currentCalculation.PickedNumber} x {multiplier}",
                CalcResult = Convert.ToInt32(currentCalculation.CurrentResult).ToString()
            };
            status.CurrentStatus = $"Step 1 doubled the sent number ({currentCalculation.PickedNumber}) and calculated a running result of {currentCalculation.CurrentResult}";
            _eventBusProvider.UpdateStatus(status);            
            return resultCalculation;
        }
    }
}
