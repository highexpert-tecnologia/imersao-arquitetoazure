<%@ WebHandler Language="C#" Class="ApiCartUpdateQty" %>
using System;using System.Web;using System.Data.SqlClient;using HighExpertStore;

public class ApiCartUpdateQty : IHttpHandler {
  public void ProcessRequest(HttpContext c){
    c.Response.ContentType="application/json";
    try{
      string body = Db.ReadBody(c.Request);
      var j = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<dynamic>(body);
      string token = j.ContainsKey("token") ? (string)j["token"] : "";
      int cartItemId = j.ContainsKey("cartItemId") ? Convert.ToInt32(j["cartItemId"]) : 0;
      int quantity = j.ContainsKey("quantity") ? Convert.ToInt32(j["quantity"]) : 1;
      if (quantity < 1) quantity = 1;

      using(var conn=Db.GetConnection()){
        conn.Open();
        var uid=Db.ValidateToken(token, conn);
        if(uid==null){ c.Response.StatusCode=401; c.Response.Write(Db.Json(new{error="Token inválido"})); return; }

        using(var chk=new SqlCommand(@"
          SELECT COUNT(1) FROM CartItems ci
          JOIN Carts ca ON ca.Id=ci.CartId AND ca.UserId=@u AND ca.Status='Active'
          WHERE ci.Id=@i", conn)){
          chk.Parameters.AddWithValue("@i", cartItemId);
          chk.Parameters.AddWithValue("@u", uid.Value);
          if((int)chk.ExecuteScalar()==0){ c.Response.StatusCode=404; c.Response.Write(Db.Json(new{error="Item não encontrado"})); return; }
        }

        using(var up=new SqlCommand("UPDATE CartItems SET Quantity=@q WHERE Id=@i", conn)){
          up.Parameters.AddWithValue("@q", quantity);
          up.Parameters.AddWithValue("@i", cartItemId);
          up.ExecuteNonQuery();
        }

        c.Response.Write(Db.Json(new{ ok=true }));
      }
    }catch(Exception ex){
      c.Response.StatusCode=500;
      c.Response.Write(Db.Json(new{error=ex.Message}));
    }
  }
  public bool IsReusable { get { return false; } }
}