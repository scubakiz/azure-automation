using MathTrickCore.Models;

namespace MathTrickCore.Interfaces
{
    public interface IEventBusProvider
    {
        bool IsConnectionActive { get; }
        object ConnectToQueueProvider();
        Task UpdateStatus(StatusMessageModel status);              
        void RegisterStatusQueueMessagesHandler();
    }
}