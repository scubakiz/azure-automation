using MathTrickCore.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MathTrickCore.Interfaces
{
    public interface ICalculationService
    {
        CalculationStepModel CalculateStep(CurrentCalculation currentCalculation);
    }
}
