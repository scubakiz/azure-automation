using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MathTrickCore.Extensions
{
    public static class MessageExtensions
    {
        public static byte[] EncodeMessage(this string jsonObject)
        {
            return Encoding.ASCII.GetBytes(jsonObject);
        }

        public static string DecodeMessage(this byte[] arrBytes)
        {
            return Encoding.Default.GetString(arrBytes);
        }

        public static string EncodeString(this string query)
        {
            return Uri.EscapeDataString(query);
        }

        public static string Base64Encode(string plainText)
        {
            var plainTextBytes = Encoding.UTF8.GetBytes(plainText);
            return Convert.ToBase64String(plainTextBytes);
        }

        public static string Base64Decode(string base64EncodedData)
        {
            var base64EncodedBytes = Convert.FromBase64String(base64EncodedData);
            return Encoding.UTF8.GetString(base64EncodedBytes);
        }
    }
}
