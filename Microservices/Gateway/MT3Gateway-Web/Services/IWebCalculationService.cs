using MathTrickCore.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MT3Gateway_Web.Services
{
    public interface IWebCalculationService
    {
        Task<List<CalculationStepModel>> PerformMathTrick3CalculationsAsync(int pickedNumber);
    }
}
