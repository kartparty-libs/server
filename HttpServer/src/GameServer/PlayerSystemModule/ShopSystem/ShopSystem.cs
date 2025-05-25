using Google.Protobuf;
using Proto;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 商城系统
/// </summary>
public class ShopSystem : BasePlayerSystem
{

    /// <summary>
    /// 商城今日购买次数记录
    /// </summary>
    private Dictionary<int, int> m_pTodayShopBuyCountRecord = new Dictionary<int, int>();

    /// <summary>
    /// 商城总购买次数记录
    /// </summary>
    private Dictionary<int, int> m_pTotalShopBuyCountRecord = new Dictionary<int, int>();

    /// <summary>
    /// 首充购买记录
    /// </summary>
    private Dictionary<int, int> m_pFirstShopBuyRecord = new Dictionary<int, int>();

    /// <summary>
    /// 待验证购买商品集合
    /// </summary>
    private ConcurrentDictionary<string, GameOrderData> m_pBuyShopItemWaitVerifys = new ConcurrentDictionary<string, GameOrderData>();

    /// <summary>
    /// 已验证购买商品集合
    /// </summary>
    private ConcurrentDictionary<string, GameOrderData> m_pBuyShopItemVerifys = new ConcurrentDictionary<string, GameOrderData>();

    /// <summary>
    /// 商品验证通过待通知客户端列表
    /// </summary>
    private List<int> m_tEventBuyShopItemVerifieds = new List<int>();

    public ShopSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
    }

    public override string GetSqlTableName() => SqlTableName.role_shopinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            string todayshopbuycountrecord = Convert.ToString(dataRow["todayshopbuycountrecord"]);
            string totalshopbuycountrecord = Convert.ToString(dataRow["totalshopbuycountrecord"]);
            string buyshopitemwaitverifys = Convert.ToString(dataRow["buyshopitemwaitverifys"]);
            string buyshopitemverifieds = Convert.ToString(dataRow["buyshopitemverifieds"]);
            string firstshopbuyrecord = Convert.ToString(dataRow["firstshopbuyrecord"]);

            var todayShopBuyCountRecord = UtilityMethod.JsonDeserializeObject<Dictionary<int, int>>(todayshopbuycountrecord);
            if (todayShopBuyCountRecord != null)
            {
                m_pTodayShopBuyCountRecord = todayShopBuyCountRecord;
            }

            var totalShopBuyCountRecord = UtilityMethod.JsonDeserializeObject<Dictionary<int, int>>(totalshopbuycountrecord);
            if (totalShopBuyCountRecord != null)
            {
                m_pTotalShopBuyCountRecord = totalShopBuyCountRecord;
            }

            var buyShopItemWaitVerifys = UtilityMethod.JsonDeserializeObject<ConcurrentDictionary<string, GameOrderData>>(buyshopitemwaitverifys);
            if (buyShopItemWaitVerifys != null)
            {
                m_pBuyShopItemWaitVerifys = buyShopItemWaitVerifys;
            }

            var buyShopItemVerifieds = UtilityMethod.JsonDeserializeObject<List<int>>(buyshopitemverifieds);
            if (buyShopItemVerifieds != null)
            {
                m_tEventBuyShopItemVerifieds = buyShopItemVerifieds;
            }

            var firstShopBuyRecord = UtilityMethod.JsonDeserializeObject<Dictionary<int, int>>(firstshopbuyrecord);
            if (firstShopBuyRecord != null)
            {
                m_pFirstShopBuyRecord = firstShopBuyRecord;
            }
        }

        DataTable orderdata = Launch.DBServer.SelectData(ServerTypeEnum.eGameServer, SqlTableName.gameorderinfo, "gameaccount", GetPlayer().GetAccount());
        int cost = 0;
        if (orderdata != null && orderdata.Rows.Count > 0)
        {
            for (int i = 0; i < orderdata.Rows.Count; i++)
            {
                DataRow dataRow = orderdata.Rows[i];
                string gameorderhash = Convert.ToString(dataRow["gameorderhash"]);
                string gameaccount = Convert.ToString(dataRow["gameaccount"]);
                int gameshopid = Convert.ToInt32(dataRow["gameshopid"]);
                int gameshopcount = Convert.ToInt32(dataRow["gameshopcount"]);
                long time = Convert.ToInt64(dataRow["time"]);
                TransactionPlatformEnum transactionplatformenum = (TransactionPlatformEnum)Convert.ToInt32(dataRow["transactionplatformenum"]);
                string cryptocointype = Convert.ToString(dataRow["cryptocointype"]);

                if (gameorderhash != null && gameorderhash != "")
                {
                    GameOrderData shopItemWaitVerifyData = new GameOrderData();
                    shopItemWaitVerifyData.orderHash = gameorderhash;
                    shopItemWaitVerifyData.shopCfgId = gameshopid;
                    shopItemWaitVerifyData.shopCount = gameshopcount;
                    shopItemWaitVerifyData.time = time;
                    shopItemWaitVerifyData.transactionPlatformEnum = transactionplatformenum;
                    shopItemWaitVerifyData.cryptoCoinType = cryptocointype;
                    m_pBuyShopItemVerifys.TryAdd(gameorderhash, shopItemWaitVerifyData);

                    Shop_Data shop_Data = ConfigManager.Shop.Get(gameshopid);
                    if (shop_Data != null)
                    {
                        cost += shop_Data.Cost;
                    }
                }
            }
        }

        if (this.GetSystem<BaseInfoSystem>().GetMonetary() == 0)
        {
            this.GetSystem<BaseInfoSystem>().SetMonetary(cost);
        }
        if (this.GetSystem<BaseInfoSystem>().GetUSDT() == 0)
        {
            this.GetSystem<BaseInfoSystem>().SetUSDT(cost);
        }
        if (this.GetSystem<BaseInfoSystem>().GetTON() == 0)
        {
            this.GetSystem<BaseInfoSystem>().SetTON(cost);
        }
    }

    public override void DayRefresh()
    {
        base.DayRefresh();
        m_pTodayShopBuyCountRecord.Clear();
        OnChangeData();
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyShopSystem resMsgBodyShopSystem = new ResMsgBodyShopSystem();
        if (m_pTodayShopBuyCountRecord.Count > 0)
        {
            foreach (var item in m_pTodayShopBuyCountRecord)
            {
                ResShopRecordData resShopRecordData = new ResShopRecordData();
                resShopRecordData.ShopCfgId = item.Key;
                resShopRecordData.BuyCount = item.Value;
                resMsgBodyShopSystem.TodayShopBuyCountRecord.Add(resShopRecordData);
            }
        }
        if (m_pTotalShopBuyCountRecord.Count > 0)
        {
            foreach (var item in m_pTotalShopBuyCountRecord)
            {
                ResShopRecordData resShopRecordData = new ResShopRecordData();
                resShopRecordData.ShopCfgId = item.Key;
                resShopRecordData.BuyCount = item.Value;
                resMsgBodyShopSystem.TotalShopBuyCountRecord.Add(resShopRecordData);
            }
        }
        if (m_pFirstShopBuyRecord.Count > 0)
        {
            foreach (var item in m_pFirstShopBuyRecord)
            {
                ResShopRecordData resShopRecordData = new ResShopRecordData();
                resShopRecordData.ShopCfgId = item.Key;
                resShopRecordData.BuyCount = item.Value;
                resMsgBodyShopSystem.FirstShopBuyRecord.Add(resShopRecordData);
            }
        }
        if (m_tEventBuyShopItemVerifieds.Count > 0)
        {
            foreach (var item in m_tEventBuyShopItemVerifieds)
            {
                resMsgBodyShopSystem.BuyShopItemVerifieds.Add(item);
            }
            m_tEventBuyShopItemVerifieds.Clear();
            OnChangeData();
        }
        return resMsgBodyShopSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();

        AddSaveCache("todayshopbuycountrecord", UtilityMethod.JsonSerializeObject(m_pTodayShopBuyCountRecord));
        AddSaveCache("totalshopbuycountrecord", UtilityMethod.JsonSerializeObject(m_pTotalShopBuyCountRecord));
        AddSaveCache("buyshopitemwaitverifys", UtilityMethod.JsonSerializeObject(m_pBuyShopItemWaitVerifys));
        AddSaveCache("buyshopitemverifieds", UtilityMethod.JsonSerializeObject(m_tEventBuyShopItemVerifieds));
        AddSaveCache("firstshopbuyrecord", UtilityMethod.JsonSerializeObject(m_pFirstShopBuyRecord));
    }

    public override void OnHandle(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
        base.OnHandle(i_nCurrTime, i_nLastHandleTime, i_nIntervalTime);

        //Dictionary<string, GameOrderData> buyShopItemWaitVerifys = m_pBuyShopItemWaitVerifys.ToDictionary();
        //foreach (var item in buyShopItemWaitVerifys)
        //{
        //    if (i_nCurrTime - item.Value.time >= 9000)
        //    {
        //        TransactionError error = TransactionError.None;
        //        if (item.Value.transactionPlatformEnum == TransactionPlatformEnum.TransactionTg)
        //        {
        //            OrderData_Ton orderData_Ton = OrderManager_Ton.Instance.GetOrderData(item.Value.orderHash);
        //            if (orderData_Ton == null)
        //            {
        //                error = TransactionError.NotFindOrder;
        //            }
        //        }
        //        item.Value.transactionError = error;
        //        BuyChestVerified(item.Value);
        //    }
        //}
    }

    public override void OnNewSeason(int i_nSeasonId)
    {
        base.OnNewSeason(i_nSeasonId);

        m_pFirstShopBuyRecord.Clear();

        OnChangeData();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 是否可购买商店物品
    /// </summary>
    /// <param name="i_nShopCfgId"></param>
    public bool IsBuyShowItem(int i_nShopCfgId)
    {
        Shop_Data shop_Data = ConfigManager.Shop.Get(i_nShopCfgId);
        if (shop_Data == null)
        {
            return false;
        }

        if (shop_Data.IsOpen == false)
        {
            return false;
        }

        if (shop_Data.TodayBuyCount > 0)
        {
            if (m_pTodayShopBuyCountRecord.TryGetValue(i_nShopCfgId, out int count) && count > 0)
            {
                return false;
            }
        }

        if (shop_Data.TotalBuyCount > 0)
        {
            if (m_pTotalShopBuyCountRecord.TryGetValue(i_nShopCfgId, out int count) && count > 0)
            {
                return false;
            }
        }
        return true;
    }

    /// <summary>
    /// 购买商城物品
    /// </summary>
    /// <param name="i_nShopCfgId"></param>
    /// <param name="i_sOrderHash"></param>
    /// <param name="i_eTransactionPlatformEnum"></param>
    /// <param name="i_eCryptoCoinType"></param>
    public void BuyShowItem(int i_nShopCfgId, string i_sOrderHash, TransactionPlatformEnum i_eTransactionPlatformEnum, string i_eCryptoCoinType)
    {
        if (i_sOrderHash == GlobalDefine.GMHash)
        {
            ReceiveShopItem(i_nShopCfgId, ReceiveShopItemWay.eBuy);
            i_eCryptoCoinType = Random.Shared.Next(0, 2) == 0 ? "USDT" : "TON";
            long value = i_eCryptoCoinType == "USDT" ? 100000 : 100000000;
            Shop_Data shop_Data = ConfigManager.Shop.Get(i_nShopCfgId);
            value = shop_Data.Cost * value;
            Launch.DBServer.InsertData(ServerTypeEnum.eGameServer, SqlTableName.gameorderinfo, new Dictionary<string, object>()
            {
                ["gameorderhash"] = "Kart_GM_" + UtilityMethod.GetUnixTimeMilliseconds(),
                ["gameaccount"] = this.GetPlayer().GetAccount(),
                ["gameshopid"] = i_nShopCfgId,
                ["gameshopcount"] = 1,
                ["time"] = UtilityMethod.GetUnixTimeMilliseconds(),
                ["transactionplatformenum"] = i_eTransactionPlatformEnum,
                ["cryptocointype"] = i_eCryptoCoinType,
                ["error"] = 0,
                ["value"] = value,
            });
        }
        else
        {
            Shop_Data shop_Data = ConfigManager.Shop.Get(i_nShopCfgId);
            // 免费 直接发奖
            if (shop_Data.Type == (int)ShopItemTypeEnum.eDailyFreeGift)
            {
                if (IsBuyShowItem(i_nShopCfgId))
                {
                    ReceiveShopItem(i_nShopCfgId, ReceiveShopItemWay.eBuy);
                }
            }
            else
            {
                //if (m_pBuyShopItemWaitVerifys.ContainsKey(i_sOrderHash))
                //{
                //    return;
                //}
                //GameOrderData shopItemWaitVerifyData = new GameOrderData();
                //shopItemWaitVerifyData.orderHash = i_sOrderHash;
                //shopItemWaitVerifyData.shopCfgId = i_nShopCfgId;
                //shopItemWaitVerifyData.shopCount = 1;
                //shopItemWaitVerifyData.transactionPlatformEnum = i_eTransactionPlatformEnum;
                //shopItemWaitVerifyData.cryptoCoinType = i_eCryptoCoinType;
                //shopItemWaitVerifyData.time = UtilityMethod.GetUnixTimeMilliseconds();
                //m_pBuyShopItemWaitVerifys.TryAdd(i_sOrderHash, shopItemWaitVerifyData);
            }
        }

        OnChangeData();
        Debug.Instance.Log($"ShopSystem BuyShowItem -> RoleId({this.GetPlayer().GetRoleId()}) ShopCfgId({i_nShopCfgId} OrderHash({i_sOrderHash})", LogType.system);
    }

    /// <summary>
    /// 购买验证通过
    /// </summary>
    /// <param name="i_sOrderHash"></param>
    public void BuyChestVerified(GameOrderData i_pGameOrderData)
    {
        if (!m_pBuyShopItemWaitVerifys.TryGetValue(i_pGameOrderData.orderHash, out GameOrderData shopItemWaitVerifyData))
        {
            shopItemWaitVerifyData = i_pGameOrderData;
        }

        if (!m_pBuyShopItemVerifys.TryAdd(i_pGameOrderData.orderHash, shopItemWaitVerifyData))
        {
            m_pBuyShopItemWaitVerifys.TryRemove(i_pGameOrderData.orderHash, out GameOrderData removeValue1);
            OnChangeData();
            return;
        }

        ReceiveShopItem(shopItemWaitVerifyData.shopCfgId, ReceiveShopItemWay.eBuy);
        m_pBuyShopItemWaitVerifys.TryRemove(i_pGameOrderData.orderHash, out GameOrderData removeValue);
        OnChangeData();

        Debug.Instance.Log($"ShopSystem BuyChestVerified -> RoleId({this.GetPlayer().GetRoleId()}) OrderHash({i_pGameOrderData.orderHash})", LogType.system);

        Launch.DBServer.InsertData(ServerTypeEnum.eGameServer, SqlTableName.gameorderinfo, new Dictionary<string, object>()
        {
            ["gameorderhash"] = shopItemWaitVerifyData.orderHash,
            ["gameaccount"] = this.GetPlayer().GetAccount(),
            ["gameshopid"] = shopItemWaitVerifyData.shopCfgId,
            ["gameshopcount"] = shopItemWaitVerifyData.shopCount,
            ["time"] = shopItemWaitVerifyData.time,
            ["transactionplatformenum"] = shopItemWaitVerifyData.transactionPlatformEnum,
            ["cryptocointype"] = shopItemWaitVerifyData.cryptoCoinType,
            ["error"] = shopItemWaitVerifyData.transactionError,
            ["value"] = shopItemWaitVerifyData.shopvalue,
        });
    }

    /// <summary>
    /// 领取商品
    /// </summary>
    /// <param name="i_nShopCfgId"></param>
    /// <param name="i_eReceiveShopItemWay"></param>
    public void ReceiveShopItem(int i_nShopCfgId, ReceiveShopItemWay i_eReceiveShopItemWay)
    {
        Shop_Data shop_Data = ConfigManager.Shop.Get(i_nShopCfgId);
        if (shop_Data == null)
        {
            return;
        }

        int rate = 1;
        if (shop_Data.Type == (int)ShopItemTypeEnum.eNormalGift && !m_pFirstShopBuyRecord.ContainsKey(i_nShopCfgId))
        {
            rate = 2;
        }

        if (shop_Data.Type != (int)ShopItemTypeEnum.eGiftCodeFreeGift)
        {
            if (!m_pTodayShopBuyCountRecord.ContainsKey(i_nShopCfgId))
            {
                m_pTodayShopBuyCountRecord.Add(i_nShopCfgId, 0);
            }
            m_pTodayShopBuyCountRecord[i_nShopCfgId]++;

            if (!m_pTotalShopBuyCountRecord.ContainsKey(i_nShopCfgId))
            {
                m_pTotalShopBuyCountRecord.Add(i_nShopCfgId, 0);
            }
            m_pTotalShopBuyCountRecord[i_nShopCfgId]++;

            if (!m_pFirstShopBuyRecord.ContainsKey(i_nShopCfgId))
            {
                m_pFirstShopBuyRecord.Add(i_nShopCfgId, 0);
            }
            m_pFirstShopBuyRecord[i_nShopCfgId]++;
        }

        if (i_eReceiveShopItemWay == ReceiveShopItemWay.eBuy)
        {
            m_tEventBuyShopItemVerifieds.Add(i_nShopCfgId);

            this.GetSystem<BaseInfoSystem>().AddMonetary(shop_Data.Cost);
            if (shop_Data.Type != (int)ShopItemTypeEnum.eDailyFreeGift)
            {
                this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent103, 1);
            }
        }

        ItemSystem itemSystem = this.GetSystem<ItemSystem>();
        itemSystem.AddItem(shop_Data.ShopItems, rate);
        itemSystem.AddItem(shop_Data.GiveShopItems);
    }

    /// <summary>
    /// 重置首充
    /// </summary>
    public void RestartFirstShowBuy()
    {
        m_pFirstShopBuyRecord.Clear();
        AddSaveCache("firstshopbuyrecord", UtilityMethod.JsonSerializeObject(m_pFirstShopBuyRecord));
    }
}

/// <summary>
/// 游戏订单数据
/// </summary>
public class GameOrderData
{
    /// <summary>
    /// 交易平台枚举
    /// </summary>
    public TransactionPlatformEnum transactionPlatformEnum;
    /// <summary>
    /// 数据货币类型
    /// </summary>
    public string cryptoCoinType;
    /// <summary>
    /// 订单Hash
    /// </summary>
    public string orderHash;
    /// <summary>
    /// 商品Id
    /// </summary>
    public int shopCfgId;
    /// <summary>
    /// 商品数量
    /// </summary>
    public int shopCount;
    /// <summary>
    /// 交易价格
    /// </summary>
    public long shopvalue;
    /// <summary>
    /// 交易时间
    /// </summary>
    public long time;

    /// <summary>
    /// 交易错误
    /// </summary>
    public TransactionError transactionError;
}