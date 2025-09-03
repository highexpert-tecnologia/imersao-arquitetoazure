<%@ WebHandler Language="C#" Class="ApiWishlistList" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;

public class ApiWishlistList : IHttpHandler {
  public void ProcessRequest(HttpContext c) {
    c.Response.ContentType = "application/json";
    try {
      string token = c.Request["token"] ?? "";

      using (var conn = Db.GetConnection()) {
        conn.Open();
        var uid = Db.ValidateToken(token, conn);
        if (uid == null) { c.Response.StatusCode = 401; c.Response.Write(Db.Json(new { error = "Token inválido" })); return; }

        using (var cmd = new SqlCommand(@"
          SELECT p.Id,p.Name,p.Description,p.Price,p.Category,p.ImageUrl
          FROM Wishlist w
          JOIN Products p ON p.Id = w.ProductId
          WHERE w.UserId=@u
          ORDER BY w.Id DESC", conn)) {
          cmd.Parameters.AddWithValue("@u", uid.Value);

          using (var r = cmd.ExecuteReader()) {
            var items = new System.Collections.Generic.List<object>();
            while (r.Read()) {
              items.Add(new {
                id = r.GetInt32(0),
                name = r.GetString(1),
                description = r.IsDBNull(2) ? "" : r.GetString(2),
                price = Math.Round(r.GetDecimal(3), 2),
                category = r.GetString(4),
                imageUrl = r.IsDBNull(5) ? "" : r.GetString(5)
              });
            }
            c.Response.Write(Db.Json(new { items = items }));
          }
        }
      }
    } catch (Exception ex) {
      c.Response.StatusCode = 500;
      c.Response.Write(Db.Json(new { error = ex.Message }));
    }
  }
  public bool IsReusable { get { return false; } }
}
