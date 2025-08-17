using Telegram.Bot;
using Telegram.Bot.Types;
using Telegram.Bot.Types.Enums;
using Telegram.Bot.Types.ReplyMarkups;

public class KartPartyBot
{
    private const string GameUrl = "http://127.0.0.1:9885/kp_game/tg_loginserver"; // 测试
    //private const string GameUrl = "http://172.31.29.225:9885/kp_game/tg_loginserver";

    // 开始标题
    private const string Start_Tital = "<b>👏 Welcome to the kartparty!</b>";
    // 开始图片
    private const string Start_ImgUrl = "https://www.kartparty.net/gameweb/tg/kartbotimg.png";
    // 开始描述
    private const string Start_Describe = "📢Upgrade your kart, earn more $wKart, boost your ranking, and get more airdrop rewards!\r\n\r\n🎁Play-to-earn airdrop right now!";
    private const string Help_Describe = "📢Dear Racer,please feel free to contact us anytime while using our products.\r\n\r\n📌QA Doc\r\nIf you have any questions, please first look for answers in the QA section.\r\nlink: https://t.me/kartpartychat/2\r\n\r\n📬 Report\r\nIf you encounter any bugs or issues you can't handle, please submit them through the report link.\r\nlink: https://docs.google.com/forms/d/19Gc_MM7UfKRCacqLKaD_MQDRYqbc4T-8uu65SwgZtV0/edit";

    // 开始按钮文本
    private const string Start_ButtonText1 = "1、🪂Understand Airdrop";
    private const string Start_ButtonText2 = "2、Follow on twitter(X)";
    private const string Start_ButtonText3 = "3、Participate in OKX Cryptopedia";

    // 开始按钮
    private InlineKeyboardMarkup Start_Markup = new(
        new[] {
        new[] { InlineKeyboardButton.WithUrl(Start_ButtonText1, "https://t.me/kartpartychat/3") },
        new[] { InlineKeyboardButton.WithUrl(Start_ButtonText2, "https://x.com/KaKarbom") },
        new[] { InlineKeyboardButton.WithUrl(Start_ButtonText3, "https://www.okx.com/download?appendQuery=true&deeplink=okx%3A%2F%2Fminiapp&appid=okluanftactivity&pageurl=/cryptopedia&cryptopediaId=45&chainId=1") }
        });

    // 底下菜单按钮
    private const string Menu_PlayGameButton = "🐵Play Game";
    private const string Menu_HelpButton = "📖 Help";
    private const string Menu_GameCenter = "🕹 Game center";
    private ReplyKeyboardMarkup Menu_Markup = new ReplyKeyboardMarkup(new[]
    {
        new[] { new KeyboardButton(Menu_PlayGameButton),new KeyboardButton(Menu_HelpButton )},
        new[] { new KeyboardButton(Menu_GameCenter) },
    })
    {
        ResizeKeyboard = true,
        OneTimeKeyboard = true,
        Selective = true,
    };

    private static string token = "7439582102:AAHj_KVUHeyWG73XxexH9zJz7y2JPfMvApY"; // 测试
    //private static string token = "7080066032:AAGCPxYlAXJKGvw8-dUV8aHL_hRN1X0Exmc";
    private TelegramBotClient BotClient = new TelegramBotClient(token);

    public async Task StartAsync()
    {
        using var cts = new CancellationTokenSource();

        // StartReceiving does not block the caller thread. Receiving is done on the ThreadPool, so we use cancellation token
        BotClient.StartReceiving(
            updateHandler: HandleUpdate,
            pollingErrorHandler: HandleError,
            cancellationToken: cts.Token
        );

        // Tell the user the bot is online
        Console.WriteLine("Start listening for updates");

        //// Send cancellation request to stop the bot
        //cts.Cancel();
    }

    // Each time a user interacts with the bot, this method is called
    private async Task HandleUpdate(ITelegramBotClient _, Update update, CancellationToken cancellationToken)
    {
        try
        {
            switch (update.Type)
            {
                // A message was received
                case UpdateType.Message:
                    HandleMessage(update.Message!);
                    break;

                // A button was pressed
                case UpdateType.CallbackQuery:
                    HandleButton(update.CallbackQuery!);
                    break;
            }
        }
        catch (Exception)
        {
            throw;
        }
    }

    private async Task HandleError(ITelegramBotClient _, Exception exception, CancellationToken cancellationToken)
    {
        //Console.Error.WriteLineAsync(exception.Message);
    }

    private async Task HandleMessage(Message msg)
    {
        var user = msg.From;
        var text = msg.Text ?? string.Empty;

        if (user is null)
            return;

        // Print to console
        //Console.WriteLine($"{user.FirstName} wrote {text}   {Thread.CurrentThread.ManagedThreadId}");

        string[] parts = text.Split(' ');
        string param = "";
        if (parts.Length > 1)
        {
            if (parts[0] == "/start")
            {
                text = parts[0];
                param = parts[1];
            }
        }

        // When we get a command, we react accordingly
        if (text.StartsWith("/"))
        {
            HandleCommand(user.Id, text, param);
        }
        else if (text.StartsWith("📖"))
        {
            HandleCommand(user.Id, text);
        }
        else if (text.StartsWith("🕹"))
        {
            HandleCommand(user.Id, text);
        }
    }

    private async Task HandleCommand(long userId, string command, string param = "")
    {
        switch (command)
        {
            case "/start":
                SendStart(userId, param);
                break;
            case "📖 Help":
                SendHelp(userId);
                break;
            case "/help":
                SendHelp(userId);
                break;
            case "🕹Play Game":
                SendPlayGame(userId);
                break;
            case "🕹 Game center":
                SendGameCenter(userId);
                break;
            case "/test":
                //await SendTest(userId);
                break;
        }

        await Task.CompletedTask;
    }

    public async Task SendStart(long userId, string param = "")
    {
        await BotClient.SendTextMessageAsync(
        userId,
        Start_Tital,
        parseMode: ParseMode.Html,
        replyMarkup: Menu_Markup  // 使用 InlineKeyboardMarkup 来显示链接按钮
    );

        await Task.Delay(100);

        BotClient.SendPhotoAsync(
            userId,
            photo: new InputFileId(Start_ImgUrl),
            caption: Start_Describe,
            parseMode: ParseMode.Markdown,
            replyMarkup: Start_Markup
        );

        string url = $"{GameUrl}/tgbot?account={userId}&source={param}";
        Task.Run(async () =>
        {
            using (HttpClient client = new HttpClient())
            {
                try
                {
                    // 发送 GET 请求
                    HttpResponseMessage response = await client.GetAsync(url);
                    // 确保请求成功
                    response.EnsureSuccessStatusCode();
                }
                catch (HttpRequestException e)
                {
                    //Console.WriteLine($"请求错误: {e.Message}");
                }
            }
        });
    }

    public async Task SendHelp(long userId)
    {
        BotClient.SendTextMessageAsync(
            userId,
            Help_Describe,
            default,
            ParseMode.Html,
            replyMarkup: null
        );
    }

    public async Task SendPlayGame(long userId)
    {
        using var cts = new CancellationTokenSource();
        string gameLink = "https://t.me/KartPartybot/KartParty";
        BotClient.SendTextMessageAsync(userId, $"{gameLink}", cancellationToken: cts.Token);
    }
    public async Task SendGameCenter(long userId)
    {
        using var cts = new CancellationTokenSource();
        string gameLink = "https://t.me/KartPartybot/KartParty";
        BotClient.SendTextMessageAsync(userId, $"{gameLink}", cancellationToken: cts.Token);
    }

    public async Task SendTest(long userId)
    {
        //Console.WriteLine($"SendTest -> userId = {userId}");

        //using var cts = new CancellationTokenSource();
        //string gameLink = "https://t.me/kartparty_bot/kartparty"; // 假设的游戏链接  
        //await BotClient.SendTextMessageAsync(userId, $"点击这里开始游戏: {gameLink}", cancellationToken: cts.Token);
    }

    private async Task HandleButton(CallbackQuery query)
    {
        string text = string.Empty;
        InlineKeyboardMarkup markup = new(Array.Empty<InlineKeyboardButton>());

        // Close the query to end the client-side loading animation
        await BotClient.AnswerCallbackQueryAsync(query.Id);

        // Replace menu text and keyboard
        await BotClient.EditMessageTextAsync(
            query.Message!.Chat.Id,
            query.Message.MessageId,
            text,
            ParseMode.Html,
            replyMarkup: markup
        );
    }
}