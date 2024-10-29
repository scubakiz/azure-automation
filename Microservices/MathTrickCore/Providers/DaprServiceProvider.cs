using MathTrickCore.Interfaces;
using MathTrickCore.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Runtime.Intrinsics.X86;
using System.Text;
using System.Text.Json;

namespace MathTrickCore.Providers
{
    public class DaprServiceProvider : ICommunicationsProvider
    {
        private readonly string _baseURL;
        private readonly JsonSerializerOptions _jsonOptions;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _clientFactory;
        private readonly ILogger<DaprEventBusProvider> _logger;
        private const int MAX_STEPS = 5;
        private readonly string[] _calcSteps = new string[MAX_STEPS];
        private readonly string _statusEndpoint = "/activate";
        private readonly string _gatewayEndpoint;

        public DaprServiceProvider(
            IConfiguration configuration,
            IHttpClientFactory clientFactory,
            ILogger<DaprEventBusProvider> logger)
        {
            _configuration = configuration;
            _clientFactory = clientFactory;
            _logger = logger;
            _calcSteps[0] = _configuration.GetValue<string>("MT3GatewayStep1Endpoint");
            _calcSteps[1] = _configuration.GetValue<string>("MT3GatewayStep2Endpoint");
            _calcSteps[2] = _configuration.GetValue<string>("MT3GatewayStep3Endpoint");
            _calcSteps[3] = _configuration.GetValue<string>("MT3GatewayStep4Endpoint");
            _calcSteps[4] = _configuration.GetValue<string>("MT3GatewayStep5Endpoint");
              
        _jsonOptions = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };


            _baseURL = (Environment.GetEnvironmentVariable("BASE_URL") ?? "http://localhost") + ":" + (Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500"); //reconfigure cpde to make requests to Dapr sidecar
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
        }    

        public async Task CallStatus()
        {
            await InvokeServiceGETString("status", "activate");            
        }

        public async Task<List<CalculationStepModel>> CallGateway(int pickedNumber)
        {   
            var response = await InvokeServiceGETResponse("gateway", "Calculations", pickedNumber.ToString());
            if (response.IsSuccessStatusCode)
            {
                var data = response.Content.ReadAsStringAsync().Result;
                return JsonSerializer.Deserialize<List<CalculationStepModel>>(data, _jsonOptions);
            }
            else
            {
                return new List<CalculationStepModel>();
            }

        }

        public async Task<CalculationStepModel> CallCalcStep(CalculationSteps step, string body)
        {            
            var currentStep = _calcSteps[(int)step];
            var response = await InvokeServiceReturnResponse(currentStep, "Calculations", body);
            if (response.IsSuccessStatusCode)
            {
                var data = response.Content.ReadAsStringAsync().Result;
                return JsonSerializer.Deserialize<CalculationStepModel>(data, _jsonOptions);
            }
            else
            {
                return new CalculationStepModel()
                {
                    CalcStep = currentStep,
                    CalcPerformed = currentStep,
                    CalcResult = $"StatusCode: {(int)response.StatusCode}, ReasonPhrase: {response.ReasonPhrase}"
                };
            }

        }


        private async Task<string> InvokeService(string serviceName, string method, string body)
        {
            // POST http://localhost:<daprPort>/v1.0/invoke/<appId>/method/<method-name>
            string invokeUrl = _baseURL + $"/v1.0/invoke/{serviceName}/method/{method}";
            var client = _clientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("Accept", "application/json");
            HttpContent content = new StringContent(body, Encoding.UTF8, "application/json");
            var response = await client.PostAsync(invokeUrl, content);
            if (response.IsSuccessStatusCode)
            {
                var data = await response.Content.ReadAsStringAsync();
                return data;
            }
            else
            {
                _logger.LogError($"InvokeServicePOST: Error invoking service {serviceName} with method {method} and body {body}");
                return null;
            }
        }

        private async Task<HttpResponseMessage> InvokeServiceReturnResponse(string serviceName, string method, string body)
        {
            // POST http://localhost:<daprPort>/v1.0/invoke/<appId>/method/<method-name>
            string invokeUrl = _baseURL + $"/v1.0/invoke/{serviceName}/method/{method}";
            var client = _clientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("Accept", "application/json");
            HttpContent content = new StringContent(body, Encoding.UTF8, "application/json");
            var response = await client.PostAsync(invokeUrl, content);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"InvokeServiceReturnResponse: Error invoking service {serviceName} with method {method} and body {body}");
            }
            return response;
        }

        private async Task<string> InvokeServiceGETString(string serviceName, string method)
        {
            // GET http://localhost:<daprPort>/v1.0/invoke/<appId>/method/<method-name>
            string invokeUrl = _baseURL + $"/v1.0/invoke/{serviceName}/method/{method}";
            var client = _clientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("Accept", "application/json");
            var response = await client.GetAsync(invokeUrl);
            if (response.IsSuccessStatusCode)
            {
                var data = await response.Content.ReadAsStringAsync();
                return data;
            }
            else
            {
                _logger.LogError($"InvokeServiceGETString: Error invoking service {serviceName} with method {method}");
                return null;
            }
        }

        private async Task<HttpResponseMessage> InvokeServiceGETResponse(string serviceName, string method, string queryParameters)
        {
            // GET http://localhost:<daprPort>/v1.0/invoke/<appId>/method/<method-name>/100
            string invokeUrl = _baseURL + $"/v1.0/invoke/{serviceName}/method/{method}/{queryParameters}";
            var client = _clientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("Accept", "application/json");
            var response = await client.GetAsync(invokeUrl);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"InvokeServiceGETResponse: Error invoking service {serviceName} with method {method} and query {queryParameters}");
            }
            return response;
        }
    }
}