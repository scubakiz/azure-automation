using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using MathTrickCore.Interfaces;
using MathTrickCore.Models;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace MT3Gateway_Gateway.Services
{
    public class CalculateAllService : ICalculateAllService
    {
        private readonly IConfiguration _configuration;
        private readonly int _retryCount;
        private readonly ICommunicationsProvider _commHelper;
        private readonly ILogger<CalculateAllService> _logger;
        private readonly IEventBusProvider _eventBusProvider;

        public CalculateAllService(
            IConfiguration configuration,
            ICommunicationsProvider commHelper,
            ILogger<CalculateAllService> logger,
            IEventBusProvider eventBusProvider)
        {
            _configuration = configuration;
            _retryCount = _configuration.GetValue<int>("RETRIES", 3);
            _commHelper = commHelper;
            _logger = logger;
            _eventBusProvider = eventBusProvider;
        }

        public List<CalculationStepModel> CallCalculateSteps(int pickedNumber)
        {
            var calcResults = new List<CalculationStepModel>();
            string currentResult = "0.0";
            CalculationSteps currentStep = CalculationSteps.Step1;
            bool continueProcessing = true;
            int retries = 0;
            var status = new StatusMessageModel()
            {
                MessageSource = "Gateway"
            };

            do
            {
                var package = new JObject(
                    new JProperty("pickedNumber", pickedNumber.ToString()),
                    new JProperty("currentResult", currentResult));
                status.CurrentStatus = $"Gateway sent number ({pickedNumber}) and current results ({currentResult}) to {currentStep}";
                _eventBusProvider.UpdateStatus(status);
                var results = _commHelper.CallCalcStep(currentStep, package.ToString(Formatting.None)).Result;
                status.CurrentStatus = $"Gateway received a result ({results.CalcResult}) from {currentStep} after {retries + 1} tries.";
                _eventBusProvider.UpdateStatus(status);
                results.CalcRetries = retries;
                results.CalcStep = currentStep.ToString();
                if (results.CalcResult.Contains("Exception") ||
                    results.CalcResult.Contains("StatusCode"))
                {
                    if (retries < _retryCount)
                    {
                        retries++;
                    }
                    else
                    {
                        calcResults.Add(results);
                        continueProcessing = false;
                    }
                }
                else
                {
                    calcResults.Add(results);
                    currentStep = currentStep.Next();
                    currentResult = results.CalcResult;
                    retries = 0;
                }

                if (currentStep == CalculationSteps.FinalStep)
                {
                    continueProcessing = false;
                    calcResults.Add(new CalculationStepModel()
                    {
                        CalcStep = "Final",
                        CalcResult = Convert.ToInt32(currentResult).ToString()
                    });
                }
            } while (continueProcessing);
            return calcResults;
        }
    }
}