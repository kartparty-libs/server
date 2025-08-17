public class Launch
{
    public static KartPartyBot KartPartyBot = new KartPartyBot();

    static void Main(string[] args)
    {
        KartPartyBot.StartAsync();

        while (true)
        {
            Thread.Sleep(1000);
        }
    }
}