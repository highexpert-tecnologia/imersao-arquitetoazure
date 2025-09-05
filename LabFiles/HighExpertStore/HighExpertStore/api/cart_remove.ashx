<%@ WebHandler Language="C#" Class="ApiCartRemove" %>
using System;using System.Web;using System.Data.SqlClient;using HighExpertStore;

public class ApiCartRemove : IHttpHandler {
  public void ProcessRequest(HttpContext c){
    c.Response.ContentType="application/json";
    try{
      string body = Db.ReadBody(c.Request);
      var j = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<dynamic>(body);
      string token = j.ContainsKey("token") ? (string)j["token"] : "";
      int cartItemId = j.ContainsKey("cartItemId") ? Convert.ToInt32(j["cartItemId"]) : 0;

      using(var conn=Db.GetConnection()){
        conn.Open();
        var uid=Db.ValidateToken(token, conn);
        if(uid==null){ c.Response.StatusCode=401; c.Response.Write(Db.Json(new{error="Token inválido"})); return; }

        using(var del=new SqlCommand(@"
          DELETE ci FROM CartItems ci
          WHERE ci.Id=@i AND EXISTS(
            SELECT 1 FROM Carts ca WHERE ca.Id=ci.CartId AND ca.UserId=@u AND ca.Status='Active'
          )", conn)){
          del.Parameters.AddWithValue("@i", cartItemId);
          del.Parameters.AddWithValue("@u", uid.Value);
          int n = del.ExecuteNonQuery();
          c.Response.Write(Db.Json(new{ ok = n>0 }));
        }
      }
    }catch(Exception ex){
      c.Response.StatusCode=500;
      c.Response.Write(Db.Json(new{error=ex.Message}));
    }
  }
  public bool IsReusable { get { return false; } }
}