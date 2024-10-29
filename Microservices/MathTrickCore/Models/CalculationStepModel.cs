using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MathTrickCore.Models
{
    public class CalculationStepModel
    {
        [JsonProperty("calcPlatform")]
        public string CalcPlatform { get; set; } = ".Net";

        [JsonProperty("calcStep")]
        public string CalcStep { get; set; } = string.Empty;

        [JsonProperty("calcPerformed")]
        public string CalcPerformed { get; set; } = string.Empty;

        [JsonProperty("calcResult")]
        public string CalcResult { get; set; } = string.Empty;

        [JsonProperty("calcRetries")]
        public int CalcRetries { get; set; } = 0;

    }
}
