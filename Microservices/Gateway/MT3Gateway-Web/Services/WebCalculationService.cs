using MathTrickCore.Models;
using MathTrickCore.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Configuration;

namespace MT3Gateway_Web.Services
{
    public class WebCalculationService : IWebCalculationService
    {
        private readonly string _mt3CalcGatewayEndpoint;
        private readonly int _retryCount;
        private readonly ICommunicationsProvider _commHelper;
        private readonly ILogger<WebCalculationService> _logger;

        public WebCalculationService(
            IConfiguration configuration,
            ICommunicationsProvider commHelper)
        {
            _commHelper = commHelper;
            _mt3CalcGatewayEndpoint = configuration["MT3GatewayAPIEndpoint"];
        }

        public async Task<List<CalculationStepModel>> PerformMathTrick3CalculationsAsync(
               int pickedNumber)
        {
            var results = new List<CalculationStepModel>();
            try
            {
                string uri = $"api/calculations/{pickedNumber}";
                var fullUri = $"{_mt3CalcGatewayEndpoint}/{uri}";
                var allResults = await _commHelper.CallGateway(pickedNumber);                
                results.AddRange(allResults);
                return results;
            }
            catch (Exception ex)
            {
                results.Add(new CalculationStepModel()
                {
                    CalcStep = "0",
                    CalcPerformed = "MT3Gateway_Web",
                    CalcResult = $"Exception: {ex.Message}"
                });
                return results;
            }
        }
    }
}
