using MathTrickCore.Interfaces;
using MathTrickCore.Models;

namespace MathTrickCore.Providers
{
    public class ServiceBusProvider : IEventBusProvider
    {
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


        public Task SendMessageToStatusQueue(string payload, string correlationToken)
        {
            throw new NotImplementedException();
        }

        public Task UpdateStatus(StatusMessageModel status)
        {
            throw new NotImplementedException();
        }
    }
}