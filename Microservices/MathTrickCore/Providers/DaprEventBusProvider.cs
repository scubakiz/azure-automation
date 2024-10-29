using Dapr.Client;
using MathTrickCore.Interfaces;
using MathTrickCore.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Text;

namespace MathTrickCore.Providers
{
    public class DaprEventBusProvider : IEventBusProvider
    {
        private readonly string _baseURL;
        private readonly string _statusQueue;
        private readonly string _pubSubName;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _clientFactory;
        private readonly ILogger<DaprEventBusProvider> _logger;

        public DaprEventBusProvider(
            IConfiguration configuration,
            IHttpClientFactory clientFactory,
            ILogger<DaprEventBusProvider> logger)
        {
            _configuration = configuration;
            _clientFactory = clientFactory;
            _logger = logger;
            _baseURL = (Environment.GetEnvironmentVariable("BASE_URL") ?? "http://localhost") + ":" + (Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500"); //reconfigure cpde to make requests to Dapr sidecar
            _statusQueue = Environment.GetEnvironmentVariable("STATUS_QUEUE_NAME") ?? "status_queue";
            _pubSubName = Environment.GetEnvironmentVariable("PUBSUB_NAME") ?? "gatewaypubsub";
        }

        public object ConnectToQueueProvider()
        {
            throw new NotImplementedException();
        }

        public bool IsConnectionActive
        {
            get
            {
                return false;
            }
        }

        public void RegisterStatusQueueMessagesHandler()
        {
            throw new NotImplementedException();
        }

        //public async Task SendMessageToStatusQueue(string payload, string correlationToken)
        //{
        //    try
        //    {
        //        await PublishMessage(payload, _statusQueue);
        //        Console.WriteLine($"Published data to queue {_statusQueue}: {payload}");
        //    }
        //    catch (Exception ex)
        //    {
        //        _logger.LogError(ex, $"DaprQueue: Error sending message to queue: {payload}");
        //        throw;
        //    }
        //}

        public async Task UpdateStatus(StatusMessageModel status)
        {
            await Task.CompletedTask;
            //using (var client = new DaprClientBuilder().Build())
            //{
            //    await client.PublishEventAsync(_pubSubName, _statusQueue, status);
            //}
        }
    }
}