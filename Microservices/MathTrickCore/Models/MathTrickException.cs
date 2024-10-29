using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MathTrickCore.Models
{
    public class MathTrickException : Exception
    {
        public string CalcStep { get; set; } = string.Empty;
        public string CalcStepName { get; set; } = string.Empty;
        public string CalcErrorMessage { get; set; } = string.Empty;
    }
}
