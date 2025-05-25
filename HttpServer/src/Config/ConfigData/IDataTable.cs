public interface IDataTable
{
    void LoadJson(string json);
    string GetTableName();
    void InitExtend();
}

public class BaseTable : IDataTable
{
    public virtual void LoadJson(string json) { }
    public virtual string GetTableName() { return ""; }
    public virtual void InitExtend() { }
}