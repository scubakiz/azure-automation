using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MathTrickCore.Models
{
    public class CurrentCalculation
    {
        [JsonProperty("pickedNumber")]
        public int PickedNumber { get; set; }
        [JsonProperty("currentResult")]
        public double CurrentResult { get; set; }
    }
}
