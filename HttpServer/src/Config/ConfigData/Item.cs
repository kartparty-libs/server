using System;
using System.Collections.Generic;
using Newtonsoft.Json;
public partial class Item_Data
{
	public int Id;
	public int Type;
	public int[] Params; 
	public int MaxCount;
	public int IsSeasonClear;

}
public partial class Item_Table : BaseTable
{
    public override string GetTableName() { return "Item"; }
    private List<Item_Data> DataList;
    public int Count {  get { return DataList.Count; } }
    public Item_Data GetItem(int index)
    {
        if (index >= DataList.Count || index < 0) return null;
        return DataList[index];
    }
    public override void LoadJson(string json)
    {
        DataList = new List<Item_Data>();
        var list = Newtonsoft.Json.JsonConvert.DeserializeObject<Item_Data[]>(json);
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
    public Item_Data Get(int key)
    {
        if (_keyToIndex != null && _keyToIndex.TryGetValue(key, out int index))
        {
            return GetItem(index);
        }
        return null;
    }
#endif

}
