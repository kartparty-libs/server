
using Google.Protobuf;
using Proto;

public class ResMsgClientData
{
    public Player player;

    private List<IMessage> m_pMessages = new List<IMessage>();
    private MsgClientHeader m_pMsgClientHeader;

    public ResMsgClientData()
    {
        m_pMsgClientHeader = new MsgClientHeader();
        m_pMsgClientHeader.Code = ResponseCodeEnum.Succeed;
        m_pMsgClientHeader.Date = UtilityMethod.GetUnixTimeMilliseconds();
        m_pMessages.Add(m_pMsgClientHeader);
    }

    public ResponseCodeEnum GetCode()
    {
        return m_pMsgClientHeader.Code;
    }

    public void SetCode(ResponseCodeEnum i_eResponseCodeEnum)
    {
        m_pMsgClientHeader.Code = i_eResponseCodeEnum;
    }

    public void SetDate(long i_nDate)
    {
        m_pMsgClientHeader.Date = i_nDate;
    }

    public void SetVersion(int i_nVersion)
    {
        m_pMsgClientHeader.Version = i_nVersion;
    }

    public void AddMessageData(IMessage i_pMessage)
    {
        if (i_pMessage == null)
        {
            return;
        }
        m_pMessages.Add(i_pMessage);
        SetDate(UtilityMethod.GetUnixTimeMilliseconds());
        SetVersion(ServerConfig.GetToInt("version"));
    }

    public void AddMessageData(List<IMessage> i_pMessages)
    {
        if (i_pMessages == null || i_pMessages.Count == 0)
        {
            return;
        }
        foreach (var item in i_pMessages)
        {
            m_pMessages.Add(item);
        }
        SetDate(UtilityMethod.GetUnixTimeMilliseconds());
        SetVersion(ServerConfig.GetToInt("version"));
    }

    public byte[] GetSendMessages()
    {
        return GlobalDefine.ProtoManager.SendMessages(m_pMessages);
    }
}
