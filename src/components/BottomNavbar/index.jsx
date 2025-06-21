// Assets
import {
  faCompactDisc,
  faDownload,
  faEyeSlash,
  faPause,
  faPlay,
  faVolumeMute,
  faVolumeUp,
  faTrash,
} from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import "./index.css";
import { useLongPress } from "@uidotdev/usehooks";

const BottomNavbar = ({
  isMuted,
  isPlaying,
  onToggleMute,
  onDownload,
  onTogglePlayPause,
  onBlacklist,
  onOpenBlacklist,
  onOpenPlaylistsViewer,
  onDelete,
}) => {
  return (
    <div className="bottom-navbar">
      <button type="button" className="nav-item" onClick={onOpenPlaylistsViewer}>
        <FontAwesomeIcon icon={faCompactDisc} className="icon" />
      </button>
      <button
        type="button"
        className="nav-item"
        onClick={onBlacklist}
        {...useLongPress(onOpenBlacklist, { threshold: 500 })}
      >
        <FontAwesomeIcon icon={faEyeSlash} className="icon" />
      </button>
      <button type="button" className="nav-item" onClick={onTogglePlayPause}>
        {!isPlaying && <FontAwesomeIcon icon={faPlay} className="icon" />}
        {isPlaying && <FontAwesomeIcon icon={faPause} className="icon" />}
      </button>
      <button type="button" className="nav-item" onClick={onDownload}>
        <FontAwesomeIcon icon={faDownload} className="icon" />
      </button>
      <button type="button" className="nav-item" onClick={onToggleMute}>
        <FontAwesomeIcon icon={!isMuted ? faVolumeUp : faVolumeMute} className="icon" />
      </button>
      <button type="button" className="nav-item" onClick={onDelete}>
        <FontAwesomeIcon icon={faTrash} className="icon" />
      </button>
    </div>
  );
};

export default BottomNavbar;
