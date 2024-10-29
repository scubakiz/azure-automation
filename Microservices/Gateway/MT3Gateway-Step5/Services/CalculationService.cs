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

namespace MT3Gateway_Step5.Services
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
                MessageSource = "Step 5",
                CurrentStatus = $"Step 5 received {currentCalculation.PickedNumber} and pre-calc results of {currentCalculation.CurrentResult}."
            };

            int failureRate = _configuration.GetValue<int>("FAILURE_RATE", 0);
            var rand = new Random();
            if (rand.NextDouble() < (failureRate / 100.0))
            {
                status.CurrentStatus = $"Step 5 generated a random error for no good reason";
                _eventBusProvider.UpdateStatus(status);
                throw new Exception("Some random problem occurred.");
            }

            // Perform current step
            // Step 5 - Subtract the original number from result.
            double previousResult = currentCalculation.CurrentResult;
            currentCalculation.CurrentResult = currentCalculation.CurrentResult - currentCalculation.PickedNumber;
            var resultCalculation = new CalculationStepModel()
            {
                CalcStep = "5",
                CalcPerformed = $"{previousResult} - {currentCalculation.PickedNumber}",
                CalcResult = Convert.ToInt32(currentCalculation.CurrentResult).ToString()
            };
            status.CurrentStatus = $"Step 5 subtracted the original number ({currentCalculation.PickedNumber}) from the previous result ({previousResult}) to generate a final result of {currentCalculation.CurrentResult}.";
            _eventBusProvider.UpdateStatus(status);
            return resultCalculation;
        }
    }
}
