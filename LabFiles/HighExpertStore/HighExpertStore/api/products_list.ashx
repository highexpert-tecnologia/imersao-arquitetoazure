<%@ WebHandler Language="C#" Class="ApiProductsList" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;using System.Text;
public class ApiProductsList:IHttpHandler{
public void ProcessRequest(HttpContext c){c.Response.ContentType="application/json";try{
string q=c.Request["q"]??"",category=c.Request["category"]??"";using(var conn=Db.GetConnection()){conn.Open();var sb=new StringBuilder();
sb.Append("SELECT Id,Name,Description,Price,Category,ImageUrl FROM Products WHERE Active=1 ");if(!string.IsNullOrWhiteSpace(q)) sb.Append("AND (Name LIKE @q OR Description LIKE @q) ");if(!string.IsNullOrWhiteSpace(category)) sb.Append("AND Category=@c ");sb.Append("ORDER BY Id DESC");
using(var cmd=new SqlCommand(sb.ToString(),conn)){if(!string.IsNullOrWhiteSpace(q)) cmd.Parameters.AddWithValue("@q","%"+q+"%");if(!string.IsNullOrWhiteSpace(category)) cmd.Parameters.AddWithValue("@c",category);
using(var r=cmd.ExecuteReader()){var L=new System.Collections.Generic.List<object>();while(r.Read()){L.Add(new{id=r.GetInt32(0),name=r.GetString(1),description=r.GetString(2),price=Math.Round(r.GetDecimal(3),2),category=r.GetString(4),imageUrl=r.IsDBNull(5)?"":r.GetString(5)});}c.Response.Write(Db.Json(new{items=L}));}}}}catch(Exception ex){c.Response.StatusCode=500;c.Response.Write(Db.Json(new{error=ex.Message}));}}public bool IsReusable{get{return false;}}}