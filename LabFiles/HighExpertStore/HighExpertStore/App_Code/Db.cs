using System;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.IO;

namespace HighExpertStore
{
    public static class Db
    {
        public static SqlConnection GetConnection()
        {
            var cs = System.Configuration.ConfigurationManager
                         .ConnectionStrings["HighExpertDb"].ConnectionString;
            return new SqlConnection(cs);
        }

        public static string ReadBody(HttpRequest request)
        {
            request.InputStream.Position = 0;
            using (var reader = new StreamReader(request.InputStream, Encoding.UTF8))
            {
                return reader.ReadToEnd();
            }
        }

        public static string Json(object obj)
        {
            var ser = new JavaScriptSerializer();
            return ser.Serialize(obj);
        }

        public static byte[] GenerateSalt(int size = 16)
        {
            var salt = new byte[size];
            using (var rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(salt);
            }
            return salt;
        }

        public static byte[] HashPassword(string password, byte[] salt)
        {
            using (var sha = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes(password);
                var salted = new byte[salt.Length + bytes.Length];
                Buffer.BlockCopy(salt, 0, salted, 0, salt.Length);
                Buffer.BlockCopy(bytes, 0, salted, salt.Length, bytes.Length);
                return sha.ComputeHash(salted);
            }
        }

        public static string ToBase64(byte[] data)
        {
            return Convert.ToBase64String(data);
        }

        public static byte[] FromBase64(string s)
        {
            return Convert.FromBase64String(s);
        }

        public static Guid NewToken()
        {
            return Guid.NewGuid();
        }

        public static int? ValidateToken(string token, SqlConnection conn)
        {
            if (string.IsNullOrEmpty(token)) return null;
            Guid tok;
            if (!Guid.TryParse(token, out tok)) return null;

            using (var cmd = new SqlCommand(
                @"SELECT UserId FROM Sessions 
                  WHERE Token=@t AND ExpiresAt > SYSUTCDATETIME()", conn))
            {
                cmd.Parameters.AddWithValue("@t", tok);
                var obj = cmd.ExecuteScalar();
                if (obj == null || obj == DBNull.Value) return null;
                return Convert.ToInt32(obj);
            }
        }
    }
}
