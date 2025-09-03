<%@ WebHandler Language="C#" Class="ApiOrdersList" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;
public class ApiOrdersList:IHttpHandler{
  public void ProcessRequest(HttpContext c){c.Response.ContentType="application/json";try{
    string token=c.Request["token"]??"";
    using(var conn=Db.GetConnection()){conn.Open();var uid=Db.ValidateToken(token,conn);
      if(uid==null){c.Response.StatusCode=401;c.Response.Write(Db.Json(new{error="Token inválido"}));return;}
      using(var cmd=new SqlCommand(@"SELECT Id,OrderNumber,Subtotal,Discount,Shipping,Total,Status,CreatedAt,Cep,Address
                                     FROM Orders WHERE UserId=@u ORDER BY Id DESC",conn)){
        cmd.Parameters.AddWithValue("@u",uid.Value);
        using(var r=cmd.ExecuteReader()){
          var L=new System.Collections.Generic.List<object>();
          while(r.Read()){
            L.Add(new{
              id=r.GetInt32(0),
              orderNumber=r.GetString(1),
              subtotal=Math.Round(r.IsDBNull(2)?0m:r.GetDecimal(2),2),
              discount=Math.Round(r.IsDBNull(3)?0m:r.GetDecimal(3),2),
              shipping=Math.Round(r.IsDBNull(4)?0m:r.GetDecimal(4),2),
              total=Math.Round(r.GetDecimal(5),2),
              status=r.GetString(6),
              createdAt=r.GetDateTime(7).ToString("yyyy-MM-dd HH:mm:ss"),
              cep=r.IsDBNull(8)?"":r.GetString(8),
              address=r.IsDBNull(9)?"":r.GetString(9)
            });
          }
          c.Response.Write(Db.Json(new{items=L}));
        }
      }
    }
  }catch(Exception ex){c.Response.StatusCode=500;c.Response.Write(Db.Json(new{error=ex.Message}));}}
  public bool IsReusable{get{return false;}}
}