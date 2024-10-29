using MathTrickCore.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MT3Gateway_Gateway.Services
{
    public interface ICalculateAllService
    {
        List<CalculationStepModel> CallCalculateSteps(int pickedNumber);
    }
}
