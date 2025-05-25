using System.Net.Http.Headers;
using System.Text;

public class HttpClientWrapper
{
    private static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(6);

    public static async Task GetAsync(string i_sUrl, Action<string>? i_fCallback = null, TimeSpan? i_pTimeout = null, Dictionary<string, string>? i_Headers = null)
    {
        using (var httpClient = new System.Net.Http.HttpClient())
        {
            httpClient.Timeout = i_pTimeout ?? DefaultTimeout;
            var request = new HttpRequestMessage(HttpMethod.Get, i_sUrl);
            if (i_Headers != null)
            {
                foreach (var header in i_Headers)
                {
                    request.Headers.TryAddWithoutValidation(header.Key, header.Value);
                }
            }
            try
            {
                var response = await httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                var responseBody = await response.Content.ReadAsStringAsync();
                i_fCallback?.Invoke(responseBody);
            }
            catch (HttpRequestException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper GetAsync 请求异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (TaskCanceledException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper GetAsync 请求超时: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (Exception e)
            {
                Debug.Instance.LogError($"HttpClientWrapper GetAsync 其他异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
        }
    }

    public static async Task GetAsync(string i_sUrl, Dictionary<string, string> i_sFormData, Action<string>? i_fCallback = null, TimeSpan? i_pTimeout = null, Dictionary<string, string>? i_Headers = null)
    {
        using (var httpClient = new System.Net.Http.HttpClient())
        {
            httpClient.Timeout = i_pTimeout ?? DefaultTimeout;
            var formDataContent = new FormUrlEncodedContent(i_sFormData);

            var request = new HttpRequestMessage(HttpMethod.Get, i_sUrl)
            {
                Content = formDataContent
            };
            if (i_Headers != null)
            {
                foreach (var header in i_Headers)
                {
                    request.Headers.TryAddWithoutValidation(header.Key, header.Value);
                }
            }
            try
            {
                var response = await httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                var responseBody = await response.Content.ReadAsStringAsync();
                i_fCallback?.Invoke(responseBody);
            }
            catch (HttpRequestException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper GetAsync 请求异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (TaskCanceledException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper GetAsync 请求超时: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (Exception e)
            {
                Debug.Instance.LogError($"HttpClientWrapper GetAsync 其他异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
        }
    }

    public static async Task PostAsync(string i_sUrl, string i_sJsonContent, Action<string, Exception>? i_fCallback, TimeSpan? i_pTimeout = null, Dictionary<string, string>? i_Headers = null)
    {
        using (var httpClient = new System.Net.Http.HttpClient())
        {
            httpClient.Timeout = i_pTimeout ?? DefaultTimeout;
            var request = new HttpRequestMessage(HttpMethod.Post, i_sUrl)
            {
                Content = new StringContent(i_sJsonContent, Encoding.UTF8, "application/json")
            };

            if (i_Headers != null)
            {
                foreach (var header in i_Headers)
                {
                    request.Headers.TryAddWithoutValidation(header.Key, header.Value);
                }
            }

            try
            {
                var response = await httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                var responseBody = await response.Content.ReadAsStringAsync();
                i_fCallback?.Invoke(responseBody, null);
            }
            catch (HttpRequestException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 请求异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null, e);
            }
            catch (TaskCanceledException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 请求超时: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null, e);
            }
            catch (Exception e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 其他异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null, e);
            }
        }
    }

    public static async Task PostAsync(string i_sUrl, byte[] i_tBinaryContent, Action<byte[]>? i_fCallback = null, TimeSpan? i_pTimeout = null)
    {
        using (var httpClient = new System.Net.Http.HttpClient())
        {
            httpClient.Timeout = i_pTimeout ?? DefaultTimeout;
            try
            {
                var content = new ByteArrayContent(i_tBinaryContent);
                content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
                var response = await httpClient.PostAsync(i_sUrl, content);
                response.EnsureSuccessStatusCode();
                var responseBody = await response.Content.ReadAsByteArrayAsync();
                i_fCallback?.Invoke(responseBody);
            }
            catch (HttpRequestException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 请求异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (TaskCanceledException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 请求超时: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (Exception e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 其他异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
        }
    }

    public static async Task PostAsync(string i_sUrl, Dictionary<string, string> i_sFormData, Action<string>? i_fCallback, TimeSpan? i_pTimeout = null, Dictionary<string, string>? i_Headers = null)
    {
        // 更改参数类型，现在接受一个字典来存储表单数据  
        using (var httpClient = new HttpClient())
        {
            httpClient.Timeout = i_pTimeout ?? DefaultTimeout; // 注意：DefaultTimeout 需要在你的类中定义  

            // 将表单数据转换为 application/x-www-form-urlencoded 格式的字符串  
            var formDataContent = new FormUrlEncodedContent(i_sFormData);

            var request = new HttpRequestMessage(HttpMethod.Post, i_sUrl)
            {
                Content = formDataContent
            };

            if (i_Headers != null)
            {
                foreach (var header in i_Headers)
                {
                    request.Headers.TryAddWithoutValidation(header.Key, header.Value);
                }
            }

            try
            {
                var response = await httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                var responseBody = await response.Content.ReadAsStringAsync();
                i_fCallback?.Invoke(responseBody);
            }
            catch (HttpRequestException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 请求异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (TaskCanceledException e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 请求超时: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
            catch (Exception e)
            {
                Debug.Instance.LogError($"HttpClientWrapper PostAsync 其他异常: {e.Message} URL：{i_sUrl}");
                i_fCallback?.Invoke(null);
            }
        }
    }
}
