package hcc;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FsShell;

public class RubyFsShell {

  private FsShell shell;

  public RubyFsShell(Configuration conf) {
    shell = new FsShell(conf);
  }

  public int run(String[] argv) throws Exception {
    return shell.run(castToString(argv));
  }

  private String[] castToString(String[] arr) {
    String[] ret = new String[arr.length];
    for (int i = 0; i < arr.length; i++) {
      ret[i] = arr[i];
    }
    return ret;
  }

}
