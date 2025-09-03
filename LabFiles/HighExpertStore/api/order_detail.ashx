<%@ WebHandler Language="C#" Class="ApiOrderDetail" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;
public class ApiOrderDetail:IHttpHandler{
  public void ProcessRequest(HttpContext c){c.Response.ContentType="application/json";try{
    string token=c.Request["token"]??"";
    int orderId=0;int.TryParse(c.Request["orderId"]??"0", out orderId);
    using(var conn=Db.GetConnection()){conn.Open();var uid=Db.ValidateToken(token,conn);
      if(uid==null){c.Response.StatusCode=401;c.Response.Write(Db.Json(new{error="Token inválido"}));return;}
      using(var chk=new SqlCommand("SELECT COUNT(1) FROM Orders WHERE Id=@o AND UserId=@u",conn)){
        chk.Parameters.AddWithValue("@o",orderId);chk.Parameters.AddWithValue("@u",uid.Value);
        if((int)chk.ExecuteScalar()==0){c.Response.StatusCode=404;c.Response.Write(Db.Json(new{error="Pedido não encontrado"}));return;}
      }
      using(var cmd=new SqlCommand(@"SELECT oi.ProductId,p.Name,oi.Quantity,oi.UnitPrice FROM OrderItems oi
                                     JOIN Products p ON p.Id=oi.ProductId WHERE oi.OrderId=@o",conn)){
        cmd.Parameters.AddWithValue("@o",orderId);
        using(var r=cmd.ExecuteReader()){
          var L=new System.Collections.Generic.List<object>();
          while(r.Read()){
            var qty=r.GetInt32(2);var unit=Math.Round(r.GetDecimal(3),2);
            L.Add(new{productId=r.GetInt32(0),name=r.GetString(1),quantity=qty,unitPrice=unit,subtotal=Math.Round(qty*unit,2)});
          }
          c.Response.Write(Db.Json(new{items=L}));
        }
      }
    }
  }catch(Exception ex){c.Response.StatusCode=500;c.Response.Write(Db.Json(new{error=ex.Message}));}}
  public bool IsReusable{get{return false;}}
}