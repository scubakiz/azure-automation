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

namespace MT3Gateway_Step2.Services
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
                MessageSource = "Step 2",
                CurrentStatus = $"Step 2 received {currentCalculation.PickedNumber} and pre-calc results of {currentCalculation.CurrentResult}."
            };
            _eventBusProvider.UpdateStatus(status);

            int failureRate = _configuration.GetValue<int>("FAILURE_RATE", 0);
            var rand = new Random();
            if (rand.NextDouble() < (failureRate / 100.0))
            {                
                status.CurrentStatus = $"Step 2 generated a random error for no good reason";
                _eventBusProvider.UpdateStatus(status);
                throw new Exception("Some random problem occurred.");
            }
            // Perform current step
            // Step 2 - Add 9 to result
            int addend = _configuration.GetValue<int>("CalcStepVariable", 9);
            double previousResult = currentCalculation.CurrentResult;
            currentCalculation.CurrentResult = currentCalculation.CurrentResult + addend;
            var resultCalculation = new CalculationStepModel()
            {
                CalcStep = "2",
                CalcPerformed = $"{previousResult} + {addend}",
                CalcResult = Convert.ToInt32(currentCalculation.CurrentResult).ToString()
            };

            status.CurrentStatus = $"Step 2 added {addend} to the previous results and generated a new result of {currentCalculation.CurrentResult}";
            _eventBusProvider.UpdateStatus(status);
            return resultCalculation;
        }
    }
}
