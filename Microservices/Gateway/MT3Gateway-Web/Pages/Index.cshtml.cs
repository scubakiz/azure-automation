using MathTrickCore.Models;
using MT3Gateway_Web.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using MathTrickCore.Interfaces;

namespace MT3Gateway_Web.Pages
{
    public class IndexModel : PageModel
    {
        private readonly IWebCalculationService _webCalculationService;
        private readonly ILogger<IndexModel> _logger;
        private readonly IConfiguration _configuration;
        private readonly IEventBusProvider _eventBusProvider;

        [BindProperty(SupportsGet = true)]
        public int PickedNumber { get; set; } = 5;

        [BindProperty(SupportsGet = true)]
        public int FinalResults { get; set; } = -1;

        [BindProperty(SupportsGet = true)]
        public string FailureRate { get; set; }

        [BindProperty]
        public bool AutoPilot { get; set; }

        public string Retries { get; set; }

        [BindProperty(SupportsGet = true)]
        public List<CalculationStepModel> CalculationActions { get; set; }
            = new List<CalculationStepModel>();

        public string GetImageName(string platformName)
        {
            string imageName = "images/netcore-100.png";
            switch (platformName)
            {
                case "Python":
                    imageName = "images/python-100.png";
                    break;
                case "NodeJS":
                    imageName = "images/nodejs-100.png";
                    break;
            }
            return imageName;
        }

        public IndexModel(IWebCalculationService webCalculationService,
                          ILogger<IndexModel> logger,
                          IConfiguration configuration,
                          IEventBusProvider eventBusProvider)
        {
            _webCalculationService = webCalculationService;
            _logger = logger;
            _configuration = configuration;
            _eventBusProvider = eventBusProvider;
            FailureRate = _configuration.GetValue<string>("FAILURE_RATE", "0") + "%";
            Retries = _configuration.GetValue<string>("RETRIES", "3");
        }

        public void OnGet()
        {
            var status = new StatusMessageModel()
            {
                MessageSource = "Web",
                CurrentStatus = $"Gateway Website Started"
            };
            _eventBusProvider.UpdateStatus(status);
        }

        public IActionResult OnPost(IFormCollection data)
        {
            FinalResults = -1; //Reset
            CalculationActions.Clear();          
            CalculationActions.AddRange(_webCalculationService.PerformMathTrick3CalculationsAsync(PickedNumber).Result);

            // Result is in the final step
            var result = CalculationActions.FirstOrDefault(x => x.CalcStep == "Final");
            if (result != null)
            {
                FinalResults = Int32.Parse(result.CalcResult);
                CalculationActions.RemoveAll(x => x.CalcStep == "Final");
            }
            return Page();
        }
    }
}
