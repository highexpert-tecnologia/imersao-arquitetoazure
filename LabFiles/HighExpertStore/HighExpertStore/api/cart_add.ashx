<%@ WebHandler Language="C#" Class="ApiCartAdd" %>
using System;using System.Web;using System.Data.SqlClient;using HighExpertStore;

public class ApiCartAdd : IHttpHandler {
  public void ProcessRequest(HttpContext c){
    c.Response.ContentType="application/json";
    try{
      string body = Db.ReadBody(c.Request);
      var j = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<dynamic>(body);
      string token = j.ContainsKey("token") ? (string)j["token"] : "";
      int productId = j.ContainsKey("productId") ? Convert.ToInt32(j["productId"]) : 0;
      int qty = j.ContainsKey("quantity") ? Convert.ToInt32(j["quantity"]) : 1;
      if(qty<1) qty=1;

      using(var conn=Db.GetConnection()){
        conn.Open();
        var uid=Db.ValidateToken(token, conn);
        if(uid==null){ c.Response.StatusCode=401; c.Response.Write(Db.Json(new{error="Token inválido"})); return; }

        int cartId=0;
        using(var f=new SqlCommand("SELECT TOP 1 Id FROM Carts WHERE UserId=@u AND Status='Active' ORDER BY Id DESC", conn)){
          f.Parameters.AddWithValue("@u", uid.Value);
          var x=f.ExecuteScalar();
          cartId = (x==null || x==System.DBNull.Value) ? 0 : Convert.ToInt32(x);
        }
        if(cartId==0){
          using(var ins=new SqlCommand("INSERT INTO Carts(UserId, Status) OUTPUT INSERTED.Id VALUES(@u,'Active')", conn)){
            ins.Parameters.AddWithValue("@u", uid.Value);
            cartId = (int)ins.ExecuteScalar();
          }
        }

        int itemId=0;
        using(var f=new SqlCommand("SELECT TOP 1 Id,Quantity FROM CartItems WHERE CartId=@c AND ProductId=@p", conn)){
          f.Parameters.AddWithValue("@c", cartId);
          f.Parameters.AddWithValue("@p", productId);
          using(var r=f.ExecuteReader()){
            if(r.Read()){
              itemId=r.GetInt32(0);
              int cur=r.GetInt32(1); r.Close();
              using(var up=new SqlCommand("UPDATE CartItems SET Quantity=@q WHERE Id=@i", conn)){
                up.Parameters.AddWithValue("@q", cur+qty);
                up.Parameters.AddWithValue("@i", itemId);
                up.ExecuteNonQuery();
              }
            }
          }
        }
        if(itemId==0){
          using(var ins=new SqlCommand("INSERT INTO CartItems(CartId,ProductId,Quantity) OUTPUT INSERTED.Id VALUES(@c,@p,@q)", conn)){
            ins.Parameters.AddWithValue("@c", cartId);
            ins.Parameters.AddWithValue("@p", productId);
            ins.Parameters.AddWithValue("@q", qty);
            itemId=(int)ins.ExecuteScalar();
          }
        }

        c.Response.Write(Db.Json(new{ ok=true, cartItemId=itemId, cartId=cartId }));
      }
    }catch(Exception ex){
      c.Response.StatusCode=500;
      c.Response.Write(Db.Json(new{error=ex.Message}));
    }
  }
  public bool IsReusable { get { return false; } }
}