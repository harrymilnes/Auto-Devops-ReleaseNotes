using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;

namespace Api_FunctionApp.Triggers
{
    public class ReleaseNoteHttpTrigger
    {
        [FunctionName("ReleaseNotesHttpTrigger")]
        public async Task<IActionResult> RunAsync(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "release-notes/{projectName}/{environmentName}/{buildNumber}")] 
            HttpRequest httpRequestData, 
            string projectName,  
            string environmentName, 
            string buildNumber)
        {
            using var streamReader = new StreamReader(httpRequestData.Body);
            var markDownContent = await streamReader.ReadToEndAsync();

            var blobName = $"{projectName}-{environmentName}-{buildNumber}-{DateTime.UtcNow:mm-dd-yyyy-HH:mm:ss}";
            await SaveReleaseToBlobAsync(blobName, markDownContent);

            return new OkResult();
        }
        
        private static async Task SaveReleaseToBlobAsync(string blobName, string markDownContent)
        {
            var blobServiceClient = new BlobServiceClient(Environment.GetEnvironmentVariable("ReleaseNotesAzureWebStorage"));
            var containerClient = blobServiceClient.GetBlobContainerClient("release-notes");
            await using Stream stream = new MemoryStream(Encoding.UTF8.GetBytes(markDownContent));
            await containerClient.UploadBlobAsync($"{blobName}.md", stream);
        }
    }
}