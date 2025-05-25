using System;
using System.Collections.Generic;
using Newtonsoft.Json;
public partial class LuckyBox_Data
{
	public int Id;
	public int ItemId;
	public int Quality;
	public int[] RandomValue; 
	public int LuckyRate;
	public int Weight;
	public string IconPathS;

}
public partial class LuckyBox_Table : BaseTable
{
    public override string GetTableName() { return "LuckyBox"; }
    private List<LuckyBox_Data> DataList;
    public int Count {  get { return DataList.Count; } }
    public LuckyBox_Data GetItem(int index)
    {
        if (index >= DataList.Count || index < 0) return null;
        return DataList[index];
    }
    public override void LoadJson(string json)
    {
        DataList = new List<LuckyBox_Data>();
        var list = Newtonsoft.Json.JsonConvert.DeserializeObject<LuckyBox_Data[]>(json);
        var len = list.Length;
        for (int i = 0; i < len; i++)
        {
            DataList.Add(list[i]);
        }
#if true
            PostLoadJson();
#endif
    }
    
#if true

    private Dictionary<int, int> _keyToIndex;
    private void PostLoadJson()
    {
        int len = DataList.Count;
		_keyToIndex = new Dictionary<int, int>(len);
		for (int i = 0;i < len; i++)
		{
			var item = DataList[i];
			var k = item.Id;
			if (!_keyToIndex.ContainsKey(k))
			{
				_keyToIndex.Add(k, i);
			}
			else
			{

			}
		}
    }
    public LuckyBox_Data Get(int key)
    {
        if (_keyToIndex != null && _keyToIndex.TryGetValue(key, out int index))
        {
            return GetItem(index);
        }
        return null;
    }
#endif

}
