<%@ WebHandler Language="C#" Class="ApiCartList" %>
using System;using System.Web;using System.Data.SqlClient;using HighExpertStore;

public class ApiCartList : IHttpHandler {
  public void ProcessRequest(HttpContext c){
    c.Response.ContentType="application/json";
    try{
      string token=c.Request["token"]??"";
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

        using(var cmd=new SqlCommand(@"
          SELECT ci.Id, ci.ProductId, ci.Quantity, p.Name, p.Price, ISNULL(p.ImageUrl,'') ImageUrl, ISNULL(p.EstimatedWeightGrams,200) Weight
          FROM CartItems ci
          JOIN Carts ca ON ca.Id=ci.CartId AND ca.UserId=@u AND ca.Status='Active'
          JOIN Products p ON p.Id=ci.ProductId
          ORDER BY ci.Id DESC", conn)){
          cmd.Parameters.AddWithValue("@u", uid.Value);
          using(var r=cmd.ExecuteReader()){
            var L=new System.Collections.Generic.List<object>();
            while(r.Read()){
              L.Add(new {
                id=r.GetInt32(0),
                productId=r.GetInt32(1),
                quantity=r.GetInt32(2),
                name=r.GetString(3),
                price=Math.Round(r.GetDecimal(4),2),
                imageUrl=r.GetString(5),
                estimatedWeightGrams=r.GetInt32(6)
              });
            }
            c.Response.Write(Db.Json(new { items=L }));
          }
        }
      }
    }catch(Exception ex){
      c.Response.StatusCode=500;
      c.Response.Write(Db.Json(new{error=ex.Message}));
    }
  }
  public bool IsReusable { get { return false; } }
}