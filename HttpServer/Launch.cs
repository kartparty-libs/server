public class Launch
{
    /// <summary>
    /// 核心
    /// </summary>
    public static Kernel Kernel = new Kernel();

    /// <summary>
    /// DB服务器
    /// </summary>
    public static DBServer DBServer = new DBServer();

    /// <summary>
    /// Http服务器
    /// </summary>
    public static HttpServer HttpServer = new HttpServer();

    /// <summary>
    /// WebSocket服务器
    /// </summary>
    public static WebSocketServer WebSocketServer = new WebSocketServer();

    /// <summary>
    /// 是否启动服务器
    /// </summary>
    public static volatile bool Start = false;

    /// <summary>
    /// 是否关闭服务器
    /// </summary>
    public static volatile bool Close = false;

    static void Main(string[] args)
    {
        Debug.Instance.LogInfo("服务器开始启动");
        ServerConfig.Initializer();
        ConfigManager.Initializer();

        // DBServer启动
        DBServer.Initializer();

        // Kernel启动
        Kernel.Initializer();
        Thread kernelServerUpdateThread = new Thread(() =>
        {
            Kernel.Update();
        });
        kernelServerUpdateThread.Start();

        // HttpServer启动
        HttpServer.Initializer();
        foreach (var item in ServerConfig.ServerOpens)
        {
            Thread httpServerThread = new Thread(() =>
            {
                HttpServer.RunServerAsync(ServerConfig.GetToInt("port", item.Key)).Wait();
            });
            httpServerThread.Start();
        }

        if (ServerConfig.GetToInt("websocket_port", ServerTypeEnum.eBattleServer) != default)
        {
            WebSocketServer.Initializer();
            Thread webSocketServerrThread = new Thread(() =>
            {
                WebSocketServer.RunServerAsync(ServerConfig.GetToInt("websocket_port", ServerTypeEnum.eBattleServer)).Wait();
            });
            webSocketServerrThread.Start();
        }

        Thread.Sleep(2000);

        Kernel.Start();

        Debug.Instance.LogInfo("服务器启动完毕");

        Start = true;
        while (!Close)
        {
            Thread.Sleep(1000);
        };

        Debug.Instance.LogInfo("服务器开始关闭");

        // 优先断开http链接
        HttpServer.Close();

        // 等待ks update完成
        kernelServerUpdateThread.Join();

        Kernel.Close();
        DBServer.Close();

        Thread.Sleep(2000);

        Debug.Instance.LogInfo("服务器关闭完成");
        System.Environment.Exit(0);
    }
}