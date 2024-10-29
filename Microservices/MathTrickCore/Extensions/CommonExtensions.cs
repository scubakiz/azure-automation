using MathTrickCore.Interfaces;
using MathTrickCore.Providers;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MathTrickCore.Extensions
{
    public static class CommonExtensions
    {

        public static void RegisterComminicationsProvider(
            this IServiceCollection services,
            IConfiguration configuration)
        {

            services.AddSingleton<ICommunicationsProvider, DaprServiceProvider>();

            //string communicationsProvider = (configuration.GetValue<string>("CommunicationsProvider") ?? "NATIVE").ToUpper();
            //switch (communicationsProvider)
            //{
            //    case "NATIVE":
            //    case "HTTP":
            //        services.AddSingleton<ICommunicationsProvider, HttpAPIProvider>();
            //        break;
            //    case "DAPR":
            //        services.AddSingleton<ICommunicationsProvider, DaprServiceProvider>();
            //        break;
            //    default:
            //        services.AddSingleton<ICommunicationsProvider, HttpAPIProvider>();
            //        break;
            //}
        }

        public static void RegisterEventBusProvider(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.AddSingleton<IEventBusProvider, DaprEventBusProvider>();

            //string eventBusProvider = (configuration.GetValue<string>("EVENT_BUS_PROVIDER") ?? "RABBITMQ").ToUpper();
            //string eventQueueName = (configuration.GetValue<string>("STATUS_QUEUE_NAME") ?? "status_queue");

            //switch (eventBusProvider)
            //{
            //    case "RABBITMQ":
            //    case "RABBIT":
            //        services.AddSingleton<IEventBusProvider, RabbitMQProvider>();
            //        break;
            //    case "SERVICEBUS":
            //        services.AddSingleton<IEventBusProvider, ServiceBusProvider>();
            //        break;
            //    case "REDIS":
            //        services.AddSingleton<IEventBusProvider, RedisProvider>();
            //        break;
            //    case "DAPR":
            //        services.AddSingleton<IEventBusProvider, DaprEventBusProvider>();
            //        break;
            //    default:
            //        services.AddSingleton<IEventBusProvider, RabbitMQProvider>();
            //        break;
            //}
        }
    }
}
