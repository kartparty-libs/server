using System.Collections.Generic;

public partial class ConfigManager
{
	private static List<IDataTable> _tables;
	public static Car_Table Car { get; private set; }
	public static CarModules_Table CarModules { get; private set; }
	public static CarUpgrade_Table CarUpgrade { get; private set; }
	public static Gift_Table Gift { get; private set; }
	public static GiftCode_Table GiftCode { get; private set; }
	public static GiftRandom_Table GiftRandom { get; private set; }
	public static Head_Table Head { get; private set; }
	public static Item_Table Item { get; private set; }
	public static KartKey_Table KartKey { get; private set; }
	public static LuckyBox_Table LuckyBox { get; private set; }
	public static LuckyTurntable_Table LuckyTurntable { get; private set; }
	public static Map_Table Map { get; private set; }
	public static MapStar_Table MapStar { get; private set; }
	public static Mining_Table Mining { get; private set; }
	public static Nickname_Table Nickname { get; private set; }
	public static Param_Table Param { get; private set; }
	public static Rank_Table Rank { get; private set; }
	public static RankTiers_Table RankTiers { get; private set; }
	public static ReceiveToken_Table ReceiveToken { get; private set; }
	public static Role_Table Role { get; private set; }
	public static Room_Table Room { get; private set; }
	public static SeasonJourney_Table SeasonJourney { get; private set; }
	public static Shop_Table Shop { get; private set; }
	public static Task_Table Task { get; private set; }
	public static TreasureChest_Table TreasureChest { get; private set; }

	private static void InitTables()
	{
		_tables = new List<IDataTable>();
		Car = AddTable(new Car_Table());
		CarModules = AddTable(new CarModules_Table());
		CarUpgrade = AddTable(new CarUpgrade_Table());
		Gift = AddTable(new Gift_Table());
		GiftCode = AddTable(new GiftCode_Table());
		GiftRandom = AddTable(new GiftRandom_Table());
		Head = AddTable(new Head_Table());
		Item = AddTable(new Item_Table());
		KartKey = AddTable(new KartKey_Table());
		LuckyBox = AddTable(new LuckyBox_Table());
		LuckyTurntable = AddTable(new LuckyTurntable_Table());
		Map = AddTable(new Map_Table());
		MapStar = AddTable(new MapStar_Table());
		Mining = AddTable(new Mining_Table());
		Nickname = AddTable(new Nickname_Table());
		Param = AddTable(new Param_Table());
		Rank = AddTable(new Rank_Table());
		RankTiers = AddTable(new RankTiers_Table());
		ReceiveToken = AddTable(new ReceiveToken_Table());
		Role = AddTable(new Role_Table());
		Room = AddTable(new Room_Table());
		SeasonJourney = AddTable(new SeasonJourney_Table());
		Shop = AddTable(new Shop_Table());
		Task = AddTable(new Task_Table());
		TreasureChest = AddTable(new TreasureChest_Table());

	}
	private static T AddTable<T>(T value) where T : IDataTable
	{
		_tables.Add(value);
		return (T)value;
	}
}
