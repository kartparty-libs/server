using DotNetty.Buffers;
using DotNetty.Codecs.Http;
using DotNetty.Common.Utilities;
using DotNetty.Transport.Channels;
using Google.Protobuf;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Proto;
using System.Collections.Specialized;
using System.Text;
using System.Web;

public class HttpServerHandler : SimpleChannelInboundHandler<IFullHttpRequest>
{
    private void Post(IChannelHandlerContext context, IHttpRequest request, List<IMessage> messages)
    {
        if (messages != null && messages.Count > 1 && RegisterProtocol.Protocols.TryGetValue(messages[1].GetType(), out RegisterProtocol.ProtocolDelegate? __delegate))
        {
            Debug.Instance.Log($"HttpServerHandler Post -> {messages[1].GetType().Name}  IP={context.Channel.RemoteAddress.ToString()}");
            MsgServerHeader msgServerHeader = messages[0] as MsgServerHeader;
            if (msgServerHeader.Hash != GlobalDefine.GMHash && msgServerHeader.Hash != GlobalDefine.ServerHash)
            {
                long openServerTime = UtilityMethod.ConvertToUtcTimestampMilliseconds(ServerConfig.GetToString("open_server_time"));
                long closeServerTime = UtilityMethod.ConvertToUtcTimestampMilliseconds(ServerConfig.GetToString("close_server_time"));
                long currTime = UtilityMethod.GetUnixTimeMilliseconds();
                if ((openServerTime > 0 && currTime < openServerTime) || (closeServerTime > 0 && currTime > closeServerTime))
                {
                    // 服务器未到达开启时间
                    ResMsgClientData responseMessageData = new ResMsgClientData();
                    responseMessageData.SetCode(ResponseCodeEnum.NotOpenServer);
                    ResMsgBodyCode resMsgBodyCode = new ResMsgBodyCode();
                    resMsgBodyCode.OpenServerTime = currTime < openServerTime ? openServerTime : 0;
                    responseMessageData.AddMessageData(resMsgBodyCode);
                    RegisterProtocol.HttpBinaryResponse(context, responseMessageData);
                    return;
                }
                else if (ServerConfig.GetToInt("version") > msgServerHeader.Version)
                {
                    // 客户端版本不匹配
                    ResMsgClientData responseMessageData = new ResMsgClientData();
                    responseMessageData.SetCode(ResponseCodeEnum.NewVersion);
                    RegisterProtocol.HttpBinaryResponse(context, responseMessageData);
                    return;
                }
            }
            __delegate(context, msgServerHeader, messages[1]);
        }
        else
        {
            string meg = "";
            if (messages != null && messages.Count > 1)
            {
                meg = messages[1].ToString();
            }
            Debug.Instance.LogWarn($"HttpServerHandler Sending 404 Not Found response {request.Uri}");
            var response = new DefaultFullHttpResponse(HttpVersion.Http11, HttpResponseStatus.NotFound, Unpooled.Empty, false);
            context.WriteAndFlushAsync(response).ContinueWith(t =>
            {
                context.CloseAsync();
            });
        }
    }

    private void Get(IChannelHandlerContext context, IHttpRequest request)
    {
        string url = "http://www.kartparty.net" + request.Uri;
        Uri uri = new Uri(url, UriKind.Absolute);
        string path = uri.AbsolutePath;
        string[] paths = path.Split('/');
        string routing = paths[paths.Length - 1];

        if ("isbindwallet".Equals(routing))
        {
            string queryString = uri.Query.TrimStart('?');
            int index = queryString.IndexOf('=');
            if (index != -1)
            {
                string key = queryString.Substring(0, index);
                string value = queryString.Substring(index + 1);
                bool isBind = WalletManager.Instance.IsBindWalletByWalletHash(value, "OKX Wallet");

                var jsonObject = new
                {
                    code = 0,
                    data = isBind
                };

                string jsonstring = JsonConvert.SerializeObject(jsonObject);
                byte[] jsontext = Encoding.UTF8.GetBytes(jsonstring);
                int jsontextLen = jsontext.Length;
                IByteBuffer jsontextContentBuffer = Unpooled.WrappedBuffer(jsontext);
                AsciiString JsontextClheaderValue = AsciiString.Cached($"{jsontextLen}");
                RegisterProtocol.HttpCommonResponse(context, jsontextContentBuffer, RegisterProtocol.TypeJson, JsontextClheaderValue);
            }
            return;
        }
        else if ("callback".Equals(routing))
        {
            UriBuilder uriBuilder = new UriBuilder("http", "www.kartparty.net")
            {
                Path = request.Uri.StartsWith("/") ? request.Uri.TrimStart('/') : request.Uri,
                Query = request.Uri.Contains('?') ? request.Uri.Substring(request.Uri.IndexOf('?')) : ""
            };

            string queryString = uriBuilder.Query.TrimStart('?');
            NameValueCollection queryParameters = HttpUtility.ParseQueryString(queryString);

            string state = queryParameters["state"];
            string code = queryParameters["code"];

            string[] states = state.Split("/");
            if (states.Length >= 2)
            {
                if ((int)ServerConfig.Environment == Convert.ToInt32(states[0]) || (int)ServerConfig.Environment >= 100)
                {
                    int serverId = CommonLoginManager.Instance.GetPlayerServerId(states[1]);
                    if (serverId > 0)
                    {
                        ReqMsgServerData reqMagStoSData = new ReqMsgServerData();

                        ReqMsgBodyParseTwitterCallbackAsync reqMsgBodyParseTwitterCallbackAsync = new ReqMsgBodyParseTwitterCallbackAsync();
                        reqMsgBodyParseTwitterCallbackAsync.State = states[1];
                        reqMsgBodyParseTwitterCallbackAsync.Code = code;

                        reqMagStoSData.AddMessageData(reqMsgBodyParseTwitterCallbackAsync);
                        HttpClientWrapper.PostAsync(ServerConfig.GetStoGSURL(serverId), reqMagStoSData.GetSendMessages());
                    }
                }
            }

            AsciiString redirectUrl = AsciiString.Cached("https://t.me/KartPartybot");
            RegisterProtocol.HttpPlainResponse(context, "", redirectUrl);
            return;
        }
        else if ("tgbot".Equals(routing))
        {
            UriBuilder uriBuilder = new UriBuilder("http", "www.kartparty.net")
            {
                Path = request.Uri.StartsWith("/") ? request.Uri.TrimStart('/') : request.Uri,
                Query = request.Uri.Contains('?') ? request.Uri.Substring(request.Uri.IndexOf('?')) : ""
            };

            string queryString = uriBuilder.Query.TrimStart('?');
            NameValueCollection queryParameters = HttpUtility.ParseQueryString(queryString);

            string account = queryParameters["account"];
            string source = queryParameters["source"];

            WalletManager.Instance.TgBotUserSource(account, source);
            RegisterProtocol.HttpPlainResponse(context, "");
        }
    }

    protected override void ChannelRead0(IChannelHandlerContext context, IFullHttpRequest request)
    {
        if (request.Method == DotNetty.Codecs.Http.HttpMethod.Post)
        {
            string[] parts = request.Uri.Split("/");
            string routing = parts[parts.Length - 1];
            if (RegisterDefine.HttpRoutingRegister.Contains(request.Uri))
            {
                if (routing == "proto")
                {
                    RoutingProto(context, request);
                }
                else if (routing == "json")
                {
                    RoutingJson(context, request);
                }
                return;
            }
            else if ("aeoncallbackurl".Equals(routing))
            {
                List<IMessage> messages = new List<IMessage>();
                byte[] content = new byte[request.Content.ReadableBytes];
                if (content.Length > 0)
                {
                    request.Content.ReadBytes(content);
                    string requestBodyString = Encoding.UTF8.GetString(content);
                    OrderManager_Aeon.Instance.OrderWebhook(requestBodyString);
                }
                byte[] responseBodyBytes = Encoding.UTF8.GetBytes("success");
                context.WriteAndFlushAsync(new DefaultFullHttpResponse(HttpVersion.Http11, HttpResponseStatus.OK, Unpooled.WrappedBuffer(responseBodyBytes))).ContinueWith(t =>
                {
                    if (t.IsCompletedSuccessfully)
                    {
                        context.CloseAsync();
                    }
                });
                return;
            }
            else if ("rebatechangestate".Equals(routing))
            {
                List<IMessage> messages = new List<IMessage>();
                byte[] content = new byte[request.Content.ReadableBytes];
                string res = "";
                if (content.Length > 0)
                {
                    request.Content.ReadBytes(content);
                    string requestBodyString = Encoding.UTF8.GetString(content);
                    RebateChangeData rebateChangeData = UtilityMethod.JsonDeserializeObject<RebateChangeData>(requestBodyString);
                    if (rebateChangeData != null)
                    {
                        res = RebateManager.Instance.RebateChangeState(rebateChangeData.Key, rebateChangeData.State);
                    }
                    else
                    {
                        res = "Operation failure";
                    }                           
                }
                byte[] responseBodyBytes = Encoding.UTF8.GetBytes(res);
                context.WriteAndFlushAsync(new DefaultFullHttpResponse(HttpVersion.Http11, HttpResponseStatus.OK, Unpooled.WrappedBuffer(responseBodyBytes))).ContinueWith(t =>
                {
                    if (t.IsCompletedSuccessfully)
                    {
                        context.CloseAsync();
                    }
                });
                return;
            }
            else if ("getrebatedatas".Equals(routing))
            {
                List<IMessage> messages = new List<IMessage>();
                byte[] content = new byte[request.Content.ReadableBytes];
                string res = "No data";
                Dictionary<string, RebateApplyForData> datas = RebateManager.Instance.GetRebateDatas(RebateState.WaitForReview);
                if (datas.Count > 0)
                {
                    res = UtilityMethod.JsonSerializeObject(datas);
                }
                byte[] responseBodyBytes = Encoding.UTF8.GetBytes(res);
                context.WriteAndFlushAsync(new DefaultFullHttpResponse(HttpVersion.Http11, HttpResponseStatus.OK, Unpooled.WrappedBuffer(responseBodyBytes))).ContinueWith(t =>
                {
                    if (t.IsCompletedSuccessfully)
                    {
                        context.CloseAsync();
                    }
                });
                return;
            }
        }
        else if (request.Method == DotNetty.Codecs.Http.HttpMethod.Options)
        {
            RoutingOptions(context, request);
            return;
        }
        else if (request.Method == DotNetty.Codecs.Http.HttpMethod.Get)
        {
            Get(context, request);
            return;
        }

        var response = new DefaultFullHttpResponse(HttpVersion.Http11, HttpResponseStatus.NotFound, Unpooled.Empty, false);
        context.WriteAndFlushAsync(response).ContinueWith(t =>
        {
            context.CloseAsync();
        });
    }

    private void RoutingProto(IChannelHandlerContext context, IFullHttpRequest request)
    {
        byte[] content = new byte[request.Content.ReadableBytes];
        request.Content.ReadBytes(content);
        List<IMessage> messages = GlobalDefine.ProtoManager.FromBytes(content);
        this.Post(context, request, messages);
    }

    private void RoutingJson(IChannelHandlerContext context, IFullHttpRequest request)
    {
        List<IMessage> messages = new List<IMessage>();
        byte[] content = new byte[request.Content.ReadableBytes];
        if (content.Length > 0)
        {
            request.Content.ReadBytes(content);
            string requestBodyString = Encoding.UTF8.GetString(content);
            Dictionary<string, JObject> requestBody = UtilityMethod.JsonDeserializeObject<Dictionary<string, JObject>>(requestBodyString);
            if (requestBody != null)
            {
                foreach (var item in requestBody)
                {
                    Type type = Type.GetType($"Proto.{item.Key}");
                    if (type != default)
                    {
                        var message = item.Value.ToObject(type);
                        if (message != null && message is IMessage __message)
                        {
                            messages.Add(__message);
                        }
                    }
                }
            }
        }
        this.Post(context, request, messages);
    }

    private void RoutingOptions(IChannelHandlerContext context, IFullHttpRequest request)
    {
        var response = new DefaultFullHttpResponse(HttpVersion.Http11, HttpResponseStatus.OK);

        response.Headers.Set(HttpHeaderNames.AccessControlAllowOrigin, "*");
        response.Headers.Set(HttpHeaderNames.AccessControlAllowMethods, "GET, POST, PUT, DELETE, OPTIONS");
        response.Headers.Set(HttpHeaderNames.AccessControlAllowHeaders, "X-Requested-With, Content-Type, Accept, Origin");

        response.Headers.Set(HttpHeaderNames.AccessControlMaxAge, "86400"); // 一天  

        if (request.Headers.TryGet(HttpHeaderNames.AccessControlRequestHeaders, out ICharSequence requestHeaders))
        {
            response.Headers.Set(HttpHeaderNames.AccessControlAllowHeaders, requestHeaders.ToString());
        }

        context.WriteAndFlushAsync(response).ContinueWith(t =>
        {
            if (t.IsFaulted || t.IsCanceled)
            {
                context.CloseAsync();
            }
        });
    }

    public override void ExceptionCaught(IChannelHandlerContext context, Exception exception)
    {
        context.CloseAsync();
        //Debug.Instance.LogError($"HttpServerHandler ExceptionCaught {exception.Message}");
    }

    public override void ChannelReadComplete(IChannelHandlerContext context)
    {
        context.Flush();
    }
}

enum RoutingEnum
{
    eNone,
    eCommon,
    eJson,
}