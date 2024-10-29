using MathTrickCore.Extensions;
using MathTrickCore.Interfaces;
using MathTrickCore.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using Polly;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;

namespace MathTrickCore.Providers
{
    public class RabbitMQProvider : IEventBusProvider
    {        
        private readonly IConfiguration _configuration;
        private readonly IConnection _connection;
        private readonly ILogger<RabbitMQProvider> _logger;
        private readonly string _queueName;
        private IModel _queueSubscriptionChannel;

        public RabbitMQProvider(
           IConfiguration configuration,
           ILogger<RabbitMQProvider> logger)
        {            
            _configuration = configuration;
            _logger = logger;
            _queueName = _configuration.GetValue<string>("STATUS_QUEUE_NAME") ?? "status_queue";
            _connection = (IConnection)ConnectToQueueProvider();

            InitExchangesAndQueues();
            string isStatusreader = (configuration.GetValue<string>("STATUS_READER") ?? "false");
            if (IsConnectionActive && bool.Parse(isStatusreader))
            {
                RegisterStatusQueueMessagesHandler();
            }
        }

        public bool IsConnectionActive
        {
            get
            {
                bool isActive = _connection != null && _connection.IsOpen;
                if (isActive)
                {
                    _logger.LogInformation("Connected to Queue Provider: RabbitMQ");
                }
                else
                {
                    _logger.LogError("NOT connected to RabbitMQ");
                }
                return isActive;
            }
        }

        public object ConnectToQueueProvider()
        {
            string rabbitVHost = _configuration.GetValue<string>("RABBITMQ_DEFAULT_VHOST") ?? "/";
            string rabbitHost = _configuration.GetValue<string>("RABBITMQ_DEFAULT_HOST") ?? "localhost";
            string rabbitUser = _configuration.GetValue<string>("RABBITMQ_DEFAULT_USER") ?? "guest";
            string rabbitPass = _configuration.GetValue<string>("RABBITMQ_DEFAULT_PASS") ?? "guest";


            if (string.IsNullOrEmpty(rabbitHost) || string.IsNullOrEmpty(rabbitUser))
            {
                _logger.LogCritical($"RabbitMQ Connection required");
                throw new Exception($"RabbitMQ Connection required");
            }
            try
            {
                _logger.LogDebug($"RabbitMQ Connection: {rabbitHost}/{rabbitUser}");

                ConnectionFactory factory = new ConnectionFactory()
                {
                    VirtualHost = rabbitVHost,
                    HostName = rabbitHost,
                    UserName = rabbitUser,
                    Password = rabbitPass
                };

                // Retry to connect 5 times, waiting 15 second between tries
                var retryPolicy = Policy.Handle<Exception>()
                   .WaitAndRetry(5, count => TimeSpan.FromSeconds(15),
                     (exception, timeSpan, retryCount, context) =>
                     {
                         _logger.LogWarning($"Retrying RabbitMQ connection: {retryCount}.  Trying again in {timeSpan} seconds");
                     });
                IConnection connection = retryPolicy.Execute(() => factory.CreateConnection());

                _logger.LogInformation($"RabbitMQ Connection: Successful");
                return connection;
            }
            catch (AggregateException e)
            {
                _logger.LogError($"RabbitMQProvider.ConnectToQueueProvider: {e.Message}");
                var innerException = e.InnerExceptions.FirstOrDefault();
                if (innerException != null)
                {
                    _logger.LogError($"RabbitMQProvider.ConnectToQueueProvider.InnerException: {innerException.Message}");
                }
                throw;
            }
        }

        private void InitExchangesAndQueues()
        {
            if (_connection.IsOpen)
            {
                // Create Queue
                using (IModel channel = _connection.CreateModel())
                {
                    // Can be replaced with config value
                    channel.QueueDeclare(_queueName, true, false, false, null);
                    channel.Close();
                }
            }
        }

        public void RegisterStatusQueueMessagesHandler()
        {
            using (IModel channel = _connection.CreateModel())
            {
                var consumer = new EventingBasicConsumer(channel);
                consumer.Received += (model, ea) =>
                {
                    var body = ea.Body.ToArray();
                    var message = Encoding.UTF8.GetString(body);
                    if (!string.IsNullOrEmpty(message))
                    {
                        var status = JsonSerializer.Deserialize<StatusMessageModel>(message);
                        if (status != null)
                        {
                            _logger.LogInformation($"Received status from: {status.MessageSource}");
                            _logger.LogInformation($"Current status: {status.CurrentStatus}");
                        }
                    }
                    channel.BasicAck(ea.DeliveryTag, false);
                };
                channel.BasicConsume(queue: _queueName,
                                     autoAck: false,
                                     consumer: consumer);
            }
        }


        public async Task SendMessageToStatusQueue(string payload, string correlationToken)
        {
            try
            {
                var token = JToken.Parse(payload);

                // Deteremine if array
                if (token is JArray)
                {
                    IEnumerable<object> requests = token.ToObject<List<object>>();
                    foreach (var message in requests)
                    {
                        SendMessage(message.ToString(), _queueName);
                    }
                }
                else if (token is JObject)
                {
                    await SendMessage(payload, _queueName);
                }
            }
            catch (Exception e)
            {
                _logger.LogError("RabbitMQProvider.SendMessageToQueue: ", e);
                throw;
            }
        }

        private async Task SendMessage(string payload, string queueEvent)
        {
            if (_connection.IsOpen)
            {
                using (IModel channel = _connection.CreateModel())
                {
                    channel.BasicPublish(exchange: string.Empty, queueEvent, null, payload.EncodeMessage());
                    _logger.LogDebug($"Sent message to {queueEvent}");
                    channel.Close();
                };
            }
        }

        public async Task UpdateStatus(StatusMessageModel status)
        {
            var payload = JsonSerializer.Serialize(status);
            await SendMessageToStatusQueue(payload, _queueName);
        }
    }
}