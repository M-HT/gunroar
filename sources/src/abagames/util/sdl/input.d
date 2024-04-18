/*
 * $Id: input.d,v 1.2 2005/07/03 07:05:23 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.input;

private import bindbc.sdl;

/**
 * Input device interface.
 */
public interface Input {
  public void handleEvent(SDL_Event *event);
  public void handleEvents();
}

public class MultipleInputDevice: Input {
 public:
  Input[] inputs;

  public void handleEvent(SDL_Event *event) {
    foreach (Input i; inputs)
      i.handleEvent(event);
  }
  public void handleEvents() {
    foreach (Input i; inputs)
      i.handleEvents();
  }
}
