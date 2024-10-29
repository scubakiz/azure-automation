using MathTrickCore.Models;

namespace MathTrickCore.Interfaces
{
    public interface ICommunicationsProvider
    {
        Task<List<CalculationStepModel>> CallGateway(int pickedNumber);
        Task CallStatus();
        Task<CalculationStepModel> CallCalcStep(CalculationSteps step, string body);
    }
}